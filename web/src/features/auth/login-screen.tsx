import { type FormEvent, useState } from "react";

import { useSession } from "../../app/auth/session-provider";

export function LoginScreen() {
  const { status, errorCode, notice, login } = useSession();
  const [loginName, setLoginName] = useState("");
  const [password, setPassword] = useState("");
  const [showPassword, setShowPassword] = useState(false);
  const isLoading = status === "authenticating";

  async function submit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    await login({ loginName, password });
  }

  const authMessages: Record<string, string> = {
    invalid_credentials: "El usuario o la contraseña son incorrectos.",
    unauthorized: "Debes iniciar sesión para continuar.",
    session_expired: "Tu sesión expiró. Inicia sesión nuevamente.",
    forbidden: "No tienes permisos para realizar esta acción.",
    csrf_failed: "La solicitud de seguridad no fue aceptada. Recarga la página e intenta nuevamente.",
  };
  const visibleError = errorCode && !notice
    ? `${errorCode}: ${authMessages[errorCode] ?? "No se pudo iniciar sesión."}`
    : null;

  return (
    <main className="auth-page">
      <section className="auth-card" aria-labelledby="login-title">
        <p className="auth-eyebrow">Cuentas Claras</p>
        <h1 id="login-title">Inicia sesión en Cuentas Claras</h1>
        <p className="auth-intro">
          Usa tu cuenta de demostración para acceder al grupo.
        </p>
        {notice && (
          <p className="auth-notice" role="status">
            {notice}
          </p>
        )}
        <form aria-label="Iniciar sesión" onSubmit={submit}>
          <div className="auth-field">
            <label htmlFor="login-name">Usuario</label>
            <input
              id="login-name"
              name="login_name"
              type="text"
              autoComplete="username"
              value={loginName}
              onChange={(event) => setLoginName(event.target.value)}
              disabled={isLoading}
              required
            />
          </div>
          <div className="auth-field">
            <label htmlFor="login-password">Contraseña</label>
            <div className="password-field">
              <input
                id="login-password"
                name="password"
                type={showPassword ? "text" : "password"}
                autoComplete="current-password"
                value={password}
                onChange={(event) => setPassword(event.target.value)}
                disabled={isLoading}
                required
              />
              <button
                type="button"
                className="password-toggle"
                aria-label={showPassword ? "Ocultar contraseña" : "Mostrar contraseña"}
                aria-pressed={showPassword}
                onClick={() => setShowPassword((visible) => !visible)}
                disabled={isLoading}
              >
                {showPassword ? "Ocultar" : "Mostrar"}
              </button>
            </div>
          </div>
          {visibleError && (
            <p className="auth-error" role="alert" aria-live="polite">
              {visibleError}
            </p>
          )}
          <button
            type="submit"
            className="auth-submit"
            disabled={isLoading}
            aria-busy={isLoading}
          >
            {isLoading ? "Ingresando…" : "Iniciar sesión"}
          </button>
        </form>
      </section>
    </main>
  );
}
