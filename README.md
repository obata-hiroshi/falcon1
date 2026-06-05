# falcon1

シンプルなオンラインエディッタを作成するための技術スタックを検討したい

要件

マルチユーザー
ドキュメント単位で管理したい。フォルダーやタグは考えない
markdown
試作品なのでインフラは無料の範囲で構築

試作品なら、第一候補はこれです。

## 推奨スタック

**Next.js / React + Supabase**

| 用途         | 技術                              |
| ---------- | ------------------------------- |
| フロント       | Next.js または Vite + React        |
| エディタ       | CodeMirror 6 または Monaco Editor  |
| Markdown表示 | `react-markdown` + `remark-gfm` |
| 認証         | Supabase Auth                   |
| DB         | Supabase PostgreSQL             |
| 権限管理       | Supabase Row Level Security     |
| ホスティング     | Cloudflare Pages / Vercel       |

Supabase は PostgreSQL、認証、Realtime などをまとめて使えるので、試作品にはかなり向いています。公式にも Postgres DB、Authentication、Realtime subscriptions などを提供すると説明されています。([Supabase][1])

## DB設計イメージ

最小構成ならこれで十分です。

```text
users
- id

documents
- id
- owner_id
- title
- body_markdown
- created_at
- updated_at

document_members
- document_id
- user_id
- role  // owner, editor, viewer
```

フォルダーやタグを考えないなら、画面はかなり単純にできます。

```text
ログイン
↓
自分が参加しているドキュメント一覧
↓
ドキュメント編集画面
```

## エディタの選択

個人的には **CodeMirror 6** がよいです。

Monaco Editor は VS Code 風で強力ですが、Markdownだけならやや重めです。シンプルなオンラインエディタなら、CodeMirror 6 のほうが扱いやすいです。

## 共同編集について

ここは2段階に分けるのがよいです。

### 試作品1：リアルタイム共同編集なし

まずはこれで十分です。

```text
編集者が保存
↓
documents.body_markdown を更新
↓
updated_at で競合チェック
```

複数人が同時に編集した場合は、

```text
他のユーザーが更新しています。再読み込みしてください。
```

で逃がします。

### 試作品2：リアルタイム反映あり

リアルタイム表示だけなら Supabase Realtime で可能です。ただし、本格的な同時編集、つまり Google Docs 的なマージまでやるなら **Yjs** が必要になります。

その場合は、

```text
React
CodeMirror 6
Yjs
Supabase / WebSocket
```

になりますが、試作品としては一気に難しくなります。

## 無料インフラ候補

フロントは **Cloudflare Pages** がかなり相性よいです。無料枠で 500 builds/month、Unlimited static requests、Unlimited bandwidth とされています。([Cloudflare Pages][2])

Vercel も使いやすいですが、Hobby Plan は Function duration などの制限があります。Next.js を使うなら便利ですが、静的寄りなら Cloudflare Pages のほうが気楽です。([Vercel][3])

## 結論

最初の試作品はこれがよいと思います。

```text
Vite + React
CodeMirror 6
react-markdown
Supabase Auth
Supabase PostgreSQL
Cloudflare Pages
```

Next.js にするより、まずは Vite + React のほうがシンプルです。

本格化するなら次の段階で、

```text
Next.js
Yjs
Supabase Realtime
課金プラン
```

を検討、でよいです。

[1]: https://supabase.com/?utm_source=chatgpt.com "Supabase | The Postgres Development Platform."
[2]: https://pages.cloudflare.com/?utm_source=chatgpt.com "Cloudflare Pages"
[3]: https://vercel.com/docs/plans/hobby?utm_source=chatgpt.com "Vercel Hobby Plan"
