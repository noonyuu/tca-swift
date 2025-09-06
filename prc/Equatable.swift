import SwiftUI
import ComposableArchitecture

// Equatable: 2つの値が等しいかを比較できるプロトコル

@Reducer
struct ProfileFeature {
    @ObservableState
    struct State: Equatable {
        var id: UUID = UUID()
        var userName: String = ""
        var mock: String = ""
        
        // カスタムEquatable
        static func == (lhs: State, rhs: State) -> Bool {
            // mock を比較から除外
            return lhs.id == rhs.id && lhs.userName == rhs.userName
        }
    }
    
    enum Action {
        case updateName(String)
        case noChange
    }
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .updateName(let name):
                // 状態が変更される
                state.userName = name
                return .none
                
            case .noChange:
                // 状態は変更されない
                return .none
            }
        }
    }
}

@Reducer
struct OptimizedFeature {
    @ObservableState
    struct State: Equatable {
        var items: [Item] = [
            Item(name: "りんご", count: 0),
            Item(name: "バナナ", count: 0),
            Item(name: "オレンジ", count: 0),
            Item(name: "ぶどう", count: 0),
            Item(name: "いちご", count: 0),
            Item(name: "メロン", count: 0),
            Item(name: "スイカ", count: 0),
            Item(name: "パイナップル", count: 0),
        ]
        var selectedId: UUID?
        var filterText: String = ""
        
        // 計算プロパティは比較に含まれない
        var filteredItems: [Item] {
            if filterText.isEmpty {
                return items
            }
            return items.filter { $0.name.contains(filterText) }
        }
    }
    
    struct Item: Equatable, Identifiable {
        let id = UUID()
        var name: String
        var count: Int
    }
    
    enum Action {
        case incrementItem(id: UUID)
        case updateFilter(String)
    }
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .incrementItem(let id):
                if let index = state.items.firstIndex(where: { $0.id == id }) {
                    state.items[index].count += 1
                }
                return .none
                
            case .updateFilter(let text):
                state.filterText = text
                return .none
            }
        }
    }
}


struct ChangeDetection: View {
    let store: StoreOf<ProfileFeature>
    
    var body: some View {
        VStack(spacing: 20) {
            // userNameが変更された場合のみ再描画
            Text("名前: \(store.userName)")
                .onAppear {
                    print("名前の再描画")
                }
            
            VStack {
                Button("名前を変更") {
                    store.send(.updateName("新しい名前"))
                }
                
                Button("同じ名前を設定") {
                    store.send(.updateName(store.userName))
                }
                
                Button("何もしない") {
                    store.send(.noChange)
                }
            }
        }
        .padding()
    }
}

struct PerformanceView: View {
    let store: StoreOf<OptimizedFeature>
    
    var body: some View {
        VStack {
            // .initで一度だけBinding作成
            TextField("フィルター", text: .init(
                get: { store.filterText },
                set: { store.send(.updateFilter($0)) }
            ))
            
            // 計算プロパティを使用
            List(store.filteredItems) { item in
                HStack {
                    Text(item.name)
                    Text("\(item.count)")
                    Button("+") {
                        store.send(.incrementItem(id: item.id))
                    }
                }
            }
        }
    }
}

#Preview {
    PerformanceView(store: Store(initialState: OptimizedFeature.State()) {
        OptimizedFeature()
    })
}

#Preview {
    ChangeDetection(store: Store(initialState: ProfileFeature.State()) {
        ProfileFeature()
    })
}
