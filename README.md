# falcon1

シンプルなマルチユーザー向け Markdown オンラインエディタの試作品設計メモです。

## 結論

最初の試作品は、次の構成を第一候補にします。

```text
Vite + React
CodeMirror 6
react-markdown + remark-gfm
Supabase Auth
Supabase PostgreSQL
Supabase Row Level Security
Cloudflare Pages
```

Next.js よりも、まずは Vite + React で小さく作る方針です。
サーバー側の複雑な処理を持たず、フロントエンドから Supabase を直接利用する構成にします。

## 要件

- マルチユーザーで利用できること
- ドキュメント単位で管理できること
- フォルダーやタグは扱わないこと
- Markdown を編集・表示できること
- 試作品として、できるだけ無料枠で構築できること
- 本格的なリアルタイム共同編集は初期対象外にすること

## 推奨スタック

| 用途 | 技術 |
| --- | --- |
| フロントエンド | Vite + React |
| エディタ | CodeMirror 6 |
| Markdown 表示 | `react-markdown` + `remark-gfm` |
| 認証 | Supabase Auth |
| DB | Supabase PostgreSQL |
| 権限管理 | Supabase Row Level Security |
| ホスティング | Cloudflare Pages |

## 技術選定の理由

### Vite + React

初期試作品では、画面構成が単純です。

```text
ログイン
↓
参加中のドキュメント一覧
↓
ドキュメント編集画面
```

Next.js のサーバー機能やルーティング機能は便利ですが、この段階では必須ではありません。
静的アプリとして Cloudflare Pages に置き、データと認証は Supabase に任せる方が構成を単純にできます。

### CodeMirror 6

Markdown 専用のオンラインエディタなら CodeMirror 6 を優先します。

Monaco Editor は VS Code 風の高機能エディタですが、Markdown 中心の試作品にはやや重めです。
CodeMirror 6 の方が軽く、React への組み込みも扱いやすいです。

### Supabase

Supabase は Auth、PostgreSQL、Realtime、Row Level Security をまとめて利用できます。
試作品では、認証・DB・権限管理を一体で扱える点が大きな利点です。

ただし、アプリケーション側で認可を完結させず、DB 側の Row Level Security を必ず前提にします。

## DB 設計

最小構成は次を基準にします。

```text
profiles
- id              // auth.users.id を参照
- display_name
- created_at

documents
- id
- owner_id        // profiles.id を参照
- title
- body_markdown
- created_at
- updated_at

document_members
- document_id     // documents.id を参照
- user_id         // profiles.id を参照
- role            // owner, editor, viewer
- created_at
```

`users` テーブルを独自に作るより、Supabase Auth の `auth.users` を認証情報の正とし、アプリ用の表示情報は `profiles` に分ける方針です。

## 権限モデル

`document_members.role` は次の意味にします。

| role | 権限 |
| --- | --- |
| owner | 閲覧、編集、メンバー管理、削除 |
| editor | 閲覧、編集 |
| viewer | 閲覧 |

RLS の基本方針は次の通りです。

- `documents` は、所有者または `document_members` に含まれるユーザーだけが参照できる
- `documents` の更新は `owner` または `editor` だけができる
- `documents` の削除は `owner` だけができる
- `document_members` の変更は `owner` だけができる

## 競合制御

初期試作品では、本格的な同時編集は実装しません。
保存時に `updated_at` を使った楽観的競合チェックを行います。

```text
編集開始時に updated_at を保持
↓
保存時に現在の updated_at と比較
↓
一致していれば保存
↓
一致していなければ保存せず、再読み込みを促す
```

競合時の表示例:

```text
他のユーザーが先に更新しています。内容を再読み込みしてください。
```

この段階では自動マージは行いません。

## 共同編集の段階

### 試作品 1: 保存ベース

最初は保存ボタンによる更新のみを扱います。

- 編集内容はローカル状態に保持
- 保存時に Supabase に更新
- `updated_at` で競合検知
- 競合時は再読み込みを促す

### 試作品 2: リアルタイム反映

次の段階で、Supabase Realtime による変更通知を検討します。

この段階でも、他ユーザーの保存を通知するだけで十分です。
Google Docs のような同時編集や自動マージはまだ対象外です。

### 試作品 3: 本格的な同時編集

本格的な共同編集を行う場合は、Yjs などの CRDT ベースの仕組みを検討します。

```text
React
CodeMirror 6
Yjs
WebSocket
Supabase または専用バックエンド
```

ただし、試作品としては難度が大きく上がるため、初期実装には含めません。

## 無料インフラの考え方

2026-06-05 時点では、Cloudflare Pages、Vercel、Supabase には無料枠があります。
ただし、無料枠の条件や制限は変わるため、実装前・公開前に公式ドキュメントを確認してください。

### Cloudflare Pages

静的な Vite + React アプリのホスティング先として相性がよいです。
Cloudflare Pages の Free plan には、月 500 builds、1 サイトあたり 20,000 files、1 ファイル 25 MiB などの制限があります。

### Vercel

Next.js を使う場合は便利ですが、この試作品では必須ではありません。
Hobby plan は無料で使えますが、利用量を超えると Hobby deployments が停止される点に注意が必要です。

### Supabase

Auth、PostgreSQL、Realtime をまとめて利用できます。
Free plan にはプロジェクト数や利用量の制限があり、継続的に超過すると制限がかかる可能性があります。

## 初期実装スコープ

最初に作る範囲は次に絞ります。

- ログイン
- ログアウト
- ドキュメント一覧
- ドキュメント作成
- ドキュメント編集
- Markdown プレビュー
- 保存時の競合検知
- owner / editor / viewer の基本権限

次は初期対象外です。

- フォルダー
- タグ
- コメント
- 履歴管理
- 自動マージ
- Yjs による同時編集
- ファイル添付
- 課金

## 参考リンク

- [Supabase](https://supabase.com/)
- [Supabase Billing FAQ](https://supabase.com/docs/guides/platform/billing-faq)
- [Cloudflare Pages limits](https://developers.cloudflare.com/pages/platform/limits/)
- [Vercel plans](https://vercel.com/docs/plans)
- [Vercel limits](https://vercel.com/docs/limits)
