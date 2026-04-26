---
name: design-doc-writer
description: Use this skill whenever the user asks for a Design Doc, 設計書, 設計検討, 設計ドキュメント, or asks you to document the design of a specific feature/function in the current codebase (including phrases like "〇〇機能の Design Doc を書いて", "この処理の設計書を執筆して", "Markdown で設計書作って", or equivalents in English). Produces a Japanese Design Doc with a fixed chapter structure, grounded in the actual source code, that includes explicit decision rationale so implementers can build the feature without ambiguity.
---

# Design Doc Writer

任意のコードベース内の特定機能について、実装者が迷わずに実装でき、かつ意思決定の理由が明示された Design Doc を日本語で執筆するスキル。

## 目的と到達水準

このスキルが目指すのは、Design Doc を読んだ実装者が以下の状態になることである。

1. **手段に迷わない**: 「どう書けばいいか」「どのライブラリを使うか」「どの順序で処理するか」を、ドキュメントを読むだけで決定できる。
2. **意思決定の理由がわかる**: 「なぜその方式を選んだか」「代替案をどう評価したか」「どんな制約から来る選択か」を理解できる。
3. **事実ベースで判断できる**: ドキュメント上の記述が実コードと整合しており、推測や願望が混入していない。

これら 3 点を常に意識して執筆する。

## ワークフロー

### Step 1: 対象機能と出力先の確認

着手前にユーザーに以下を確認する（すでに明確ならスキップしてよい）。

- 対象機能は何か（例: ユーザーの指示から特定できる「〇〇取り込み」「〇〇認証」など）
- 出力ファイル名のスラッグ（指定がなければ `docs/design-<kebab-case-feature>.md` を提案する）

### Step 2: 調査

コードの事実に基づいた記述を行うため、以下を読む。推測や「こうだろう」での執筆は禁止。読まずに書かない。

調査の順序と観点:

1. **プロジェクト概要ドキュメント**: `README.md`、`CLAUDE.md`、`docs/` 配下などに全体像をまとめたファイルがあれば最初に読む。
2. **エントリポイント／ルーティング**: HTTP サービスなら `src/server.*`・`src/app.*`・`src/routes/`、CLI なら `bin/` や `cmd/`、Lambda なら `handler.*` など、対象機能の入口を特定する。
3. **対象機能の制御コード**: コントローラ／ハンドラ／ワーカーなど、対象機能が分岐している箇所。エントリポイントから辿るか、機能名の Grep で見つける。
4. **関連する業務ロジック／サービス層**: `src/services/`、`src/lib/`、`src/domain/`、`internal/` など、ドメインロジックを置く慣習フォルダを横断して、対象機能が依存するモジュールを全て読む。
5. **型定義／スキーマ**: `*.types.ts`、`*.d.ts`、`src/types.ts`、`schema.ts`、`schema.sql`、`*.proto` など、対象機能が扱うデータ構造の定義。
6. **依存関係とランタイム設定**: `package.json`／`requirements.txt`／`go.mod`／`Cargo.toml`／`pom.xml` などの依存宣言。`Dockerfile`／`docker-compose.yml`／`app.yaml`／`deployment.yaml` などの実行環境設定。
7. **設定ファイル／環境変数**: `.env.example`、`config/*.ts`、`application.yml` など。環境変数はコード中の参照（`process.env.X`、`os.Getenv("X")` 等）と突き合わせる。

プロジェクト固有のディレクトリ構造や命名規則に合わせて、上記を柔軟に読み替えること。存在しないファイルを無理に探す必要はない。

### Step 3: 執筆

`references/template.md` に定義された章立てを**そのまま**使う。章立てを増減・変更しない。

各章の書き方、執筆原則、よくある誤り、自己チェックリストは `references/writing-guide.md` を読んで適用する。

### Step 4: 保存と自己チェック

出力先ディレクトリ (`docs/`) が存在しなければ作成する。書き上げた後、`references/writing-guide.md` のセルフチェックリストで自己レビューを行う。「なぜ」が 10 箇所以上ある・実装者が迷う余地が残っていない、などを確認する。

## 章立て（厳守）

以下の章立てを変更しないこと。セクションの追加・削除・順序変更は行わない。詳細は `references/template.md` を参照。

```
# <機能名>

**日付:** <YYYY-MM-DD>

## 概要
## 要件
## 設計
### 定数
### 型定義
### アーキテクチャ
### Firebase Firestore のコレクション/ドキュメントスキーマ
### Firebase Storage
```

**日付**は今日の日付（ユーザーの現在日付として提供されている値、または `date +%Y-%m-%d`）を使う。

対象機能が **Firebase Firestore** あるいは **Firebase Storage** を利用しない場合は、該当セクションを削除せず「本機能では利用しない。」と 1 行書いて残す。章立てを保つことで、同じプロジェクト内の Design Doc 間で比較しやすくなる。どうしても章立てを変えたい場合はユーザーに確認する。

## 執筆原則（最重要）

1. **実装者が手段に迷わないレベルの具体性**: 「〜のこと」「必ず〜経由で参照する」「別の選択肢を採らない」など、代替案を排除する明示的な指示を入れる。「〜することもできる」「〜してもよい」のような曖昧な表現は避ける。
2. **「なぜその方式にしたか」の意思決定理由を随所に明示**: 選定理由、トレードオフ、却下した代替案を各節に織り込む。太字で **理由:** あるいは **設計理由:** のラベルで示すと読み手が見つけやすい。
3. **日本語で記述**: 技術用語・コード識別子・定数名・関数名・クラス名・型名・ファイルパス・環境変数名は英語のまま。地の文は日本語。
4. **コードに書いてある事実を元にする**: 定数値・ファイルパス・関数名・型定義は実装を読んで抽出する。値が変わりうる部分は「(`path/to/file.ts` の `CONSTANT_NAME` 定数)」のように出典を示すと保守性が上がる。
5. **推測を混ぜない**: コードから読み取れない事項は、断定ではなく「想定: ...」として書くか、あるいは書かない。

## 成果物の配置

- ファイル: `docs/design-<feature-slug>.md`（プロジェクトルート基準。プロジェクトの Design Doc 配置慣習が異なる場合はユーザーに確認）
- `docs/` が無ければ作成する
- 書き上げたらユーザーに「書き上がった」と伝え、主要セクションのタイトル一覧を示す（詳細は不要）

## 参考ファイル

このスキルは以下の参考ファイルを持つ。執筆時は両方を読むこと。

- `references/template.md` — 章立てと各セクションの骨格・記述例
- `references/writing-guide.md` — 執筆原則の詳説、よくある誤り、セルフチェックリスト
