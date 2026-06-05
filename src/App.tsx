import { Link, Navigate, Route, Routes } from 'react-router-dom';
import { isSupabaseConfigured } from './lib/supabase';

function AppShell() {
  return (
    <div className="app-shell">
      <header className="app-header">
        <Link className="brand" to="/">
          falcon1
        </Link>
        <nav className="nav-links">
          <Link to="/login">ログイン</Link>
          <Link to="/documents">ドキュメント</Link>
        </nav>
      </header>
      <main className="app-main">
        <Routes>
          <Route path="/" element={<HomePage />} />
          <Route path="/login" element={<LoginPage />} />
          <Route path="/documents" element={<DocumentsPage />} />
          <Route path="*" element={<Navigate to="/" replace />} />
        </Routes>
      </main>
    </div>
  );
}

function HomePage() {
  return (
    <section className="hero">
      <p className="eyebrow">Markdown editor prototype</p>
      <h1>マルチユーザー向け Markdown エディタ</h1>
      <p>
        Phase 1 では、認証前後の画面構成、ルーティング、Supabase 接続設定の土台を用意します。
      </p>
      {!isSupabaseConfigured && (
        <p className="notice">
          Supabase 接続は未設定です。`.env` に `VITE_SUPABASE_URL` と
          `VITE_SUPABASE_ANON_KEY` を設定してください。
        </p>
      )}
    </section>
  );
}

function LoginPage() {
  return (
    <section className="panel">
      <h1>ログイン</h1>
      <p>Supabase Auth を使ったログイン画面を Phase 3 で実装します。</p>
    </section>
  );
}

function DocumentsPage() {
  return (
    <section className="panel">
      <h1>ドキュメント一覧</h1>
      <p>参加中のドキュメント一覧と新規作成を Phase 4 で実装します。</p>
    </section>
  );
}

export function App() {
  return <AppShell />;
}
