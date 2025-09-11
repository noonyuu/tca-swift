import ComposableArchitecture
import SwiftUI

@Reducer
struct AddContactFeature {
    @ObservableState
    struct State: Equatable {
        // 編集の独立性 - 子は編集中ので＝たを独自に管理できる(キャンセル時は破棄できる)
        // 単一責任 - 子は編集に関するロジックに集中できる
        // トランザクション管理 - 保存やキャンセルの操作を子が担当できる(親のデータに影響しない)
        var contact: Contact
    }
    enum Action {
        case cancelButtonTapped
        case delegate(Delegate)
        case saveButtonTapped
        case setName(String)
    }
    enum Delegate: Equatable {
        // case cancel
        case saveContact(Contact)
    }
    @Dependency(\.dismiss) var dismiss
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .cancelButtonTapped:
                return .run { _ in await self.dismiss() }

            case .delegate:
                return .none

            case .saveButtonTapped:
                // キャプチャリストでstate.contactを保持しておく
                return .run { [contact = state.contact] send in
                    // 親に通知
                    await send(.delegate(.saveContact(contact)))
                    // 画面を閉じる
                    await self.dismiss()
                }
            // 悪い例
            // return .run { send in
            //     // stateは非同期クロージャ内で直接アクセスできない
            //     await send(.delegate(.saveContact(state.contact)))
            // }

            case let .setName(name):
                state.contact.name = name
                return .none
            }
        }
    }
}

struct AddContactView: View {
    @Bindable var store: StoreOf<AddContactFeature>

    var body: some View {
        Form {
            TextField("Name", text: $store.contact.name.sending(\.setName))
            Button("Save") {
                store.send(.saveButtonTapped)
            }
        }
        .toolbar {
            ToolbarItem {
                Button("Cancel") {
                    store.send(.cancelButtonTapped)
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        AddContactView(
            store: Store(
                initialState: AddContactFeature.State(
                    contact: Contact(
                        id: UUID(),
                        name: "Blob"
                    )
                )
            ) {
                AddContactFeature()
            }
        )
    }
}
