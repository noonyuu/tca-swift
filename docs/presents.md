# @Presents とは

## TCA が提供するプロパティラッパーで子機能の表示状態を管理する

```Swift ContactsFeature.swift参考
@Presents var addContact: AddContactFeature.State? // 子画面
@Presents var alert: AlertState<Action.Alert>? // アラート
@Presents var confirmationDialog: ConfirmationDialogState<Action>? // ダイアログ
```

### 役割

1. 表示/非表示の制御
   1. nil → 非表示
   2. 値あり → 表示
2. 自動的な Action 変換
   1. 子の Action を PresentationAction でラップ
3. Binding の提供
   1. 内部で Binding を生成できる仕組みを持っている
   2. $store.scope で使える特別な Binding

### 通常の Optional との違い

```Swift
// 通常のOptional
var addContact: AddContactFeature.State?
// .ifLetが動作しないので$でBinding取得不可

// @Presents
@Presents var addContact: AddContactFeature.State?
// .ifLetで子Reducer統合するから$でBinding取得可能
```

### 動作フロー

```Swift
// 1. 値を設定
state.addContact = AddContactFeature.State(...) // 子画面表示

// 2. TCAが自動変換
子: send(.saveButtonTapped)
↓
親: addContact(.presented(.saveButtonTapped))として受信

// 3. nilに設定
state.addContact = nil // 子画面を閉じる
```

### View 側での使用

```Swift
.sheet(
    // @PresentsだからこのBinding記法が使える
    item: $store.scope(state: \.addContact, action: \.addContact)
) { store in
    AddContactView(store: store)
}
// 同様に取得可
.alert($store.scope(state: \.alert, action: \.alert))
```

### Reducer 側での統合

```Swift
var body: some ReducerOf<Self> {
  Reduce { ... }
  // $付きのKeyPathが必要(@Presentsの証)
  .ifLet(\.$addContact, action: \.addContact) {
    AddContactFeature()
  }
}
```

### ＠Presents がやってくれること

1. 子の生成/破棄の自動管理
2. Action 変換 (presented/dismiss)
3. View 用の Binding 提供
4. メモリの最適化(不要時は完全破棄)
