import ComposableArchitecture
import Foundation
import SwiftUI

// IDの一元管理 - UUIDを親で生成することで一意性を保証
// ビジネスロジックの集約 - 生成ルールやデフォルト値などを親が管理
// 親が全体のデータを把握しているから初期値を適切に設定できる
struct Contact: Equatable, Identifiable {
    let id: UUID
    var name: String
}

@Reducer
struct ContactsFeature {
    @ObservableState
    struct State: Equatable {
        // プレゼンテーション制御 - nil で非表示、値ありで表示を簡単に管理できる
        // TCA の .ifLet でこの生成・破棄を自動化できる
        // メモリの効率化 - 不要な状態を持たず、必要なときだけ生成される
        @Presents var addContact: AddContactFeature.State?
        @Presents var alert: AlertState<Action.Alert>?
        var contacts: IdentifiedArrayOf<Contact> = []
    }
    enum Action {
        case addButtonTapped
        case addContact(PresentationAction<AddContactFeature.Action>)
        case alert(PresentationAction<Alert>)
        case deleteButtonTapped(id: Contact.ID)
        // 削除確認という内部的なUI状態なのでAction内に含める
        enum Alert: Equatable {
            case confirmDelete(id: Contact.ID)
        }
    }
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .addButtonTapped:
                state.addContact = AddContactFeature.State(
                    contact: Contact(id: UUID(), name: "")
                )
                return .none

            // case .addContact(.presented(.delegate(.cancel))):
            //     state.addContact = nil
            //     return .none

            // 親のaddContactアクション -> 子が表示中の場合 -> 子のdelegateアクション -> saveContactアクション -> 値を取り出す
            case let .addContact(.presented(.delegate(.saveContact(contact)))):
                // guard let contact = state.addContact?.contact
                // else { return .none }
                state.contacts.append(contact)
                state.addContact = nil
                return .none

            case .addContact:
                return .none

            case let .alert(.presented(.confirmDelete(id: id))):
                state.contacts.remove(id: id)
                return .none

            case .alert:
                return .none

            case let .deleteButtonTapped(id: id):
                state.alert = AlertState {
                    TextState("Are you sure?")
                } actions: {
                    ButtonState(role: .destructive, action: .confirmDelete(id: id)) {
                        TextState("Delete")
                    }
                }
                return .none
            }
        }
        .ifLet(\.$addContact, action: \.addContact) {
            AddContactFeature()
        }
        .ifLet(\.$alert, action: \.alert)
    }
}

struct ContactsView: View {
    @Bindable var store: StoreOf<ContactsFeature>

    var body: some View {
        NavigationStack {
            List {
                ForEach(store.contacts) { contact in
                    HStack {
                        Text(contact.name)
                        Spacer()
                        Button {
                            store.send(.deleteButtonTapped(id: contact.id))
                        } label: {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                        }
                    }
                }
            }
            .navigationTitle("Contacts")
            .toolbar {
                ToolbarItem {
                    Button {
                        store.send(.addButtonTapped)
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
        }
        .sheet(
            item: $store.scope(state: \.addContact, action: \.addContact)
        ) { addContactStore in
            NavigationStack {
                AddContactView(store: addContactStore)
            }
        }
        .alert($store.scope(state: \.alert, action: \.alert))
    }
}

#Preview {
    ContactsView(
        store: Store(
            initialState: ContactsFeature.State(
                contacts: [
                    Contact(id: UUID(), name: "Blob"),
                    Contact(id: UUID(), name: "Blob Jr"),
                    Contact(id: UUID(), name: "Blob Sr"),
                ]
            )
        ) {
            ContactsFeature()
        }
    )
}
