import { type FormEvent, useState } from "react";

import { Icon } from "../../components/icons";
import { Button, StatusBadge } from "../../components/ui";
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
    csrf_failed:
      "La solicitud de seguridad no fue aceptada. Recarga la página e intenta nuevamente.",
  };
  const visibleError =
    errorCode && !notice
      ? `${errorCode}: ${authMessages[errorCode] ?? "No se pudo iniciar sesión."}`
      : null;

  return (
    <main className="auth-page">
      <div className="auth-layout">
        <section className="auth-showcase" aria-label="Cuentas Claras">
          <div className="auth-brand-lockup">
            <span className="brand-mark brand-mark-large" aria-hidden="true">
              <Icon name="wallet" />
            </span>
            <span>
              <strong>Cuentas Claras</strong>
              <small>Gastos compartidos sin confusiones</small>
            </span>
          </div>
          <div className="auth-showcase-copy">
            <StatusBadge tone="info">Grupo 2 · Spec-Driven Development</StatusBadge>
            <h2>Todo el grupo entiende quién pagó, cuánto debe y cómo saldar.</h2>
            <p>
              Personas, gastos, totales y pagos sugeridos sincronizados con el
              servidor como única fuente de verdad.
            </p>
          </div>
          <div className="auth-feature-list" aria-hidden="true">
            <span><Icon name="receipt" /> Gastos claros</span>
            <span><Icon name="chart" /> Totales exactos</span>
            <span><Icon name="settlement" /> Cierre simple</span>
          </div>
        </section>

        <section className="auth-card" aria-labelledby="login-title">
          <div className="auth-card-header">
            <p className="auth-eyebrow">Acceso seguro</p>
            <h1 id="login-title">Inicia sesión en Cuentas Claras</h1>
            <p className="auth-intro">
              Usa tu cuenta de demostración para acceder al grupo.
            </p>
          </div>
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
                placeholder="demo.owner"
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
                  placeholder="••••••••"
                  required
                />
                <button
                  type="button"
                  className="password-toggle"
                  aria-label={
                    showPassword ? "Ocultar contraseña" : "Mostrar contraseña"
                  }
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
            <Button
              type="submit"
              className="auth-submit"
              disabled={isLoading}
              aria-busy={isLoading}
            >
              {isLoading ? "Ingresando…" : "Iniciar sesión"}
            </Button>
          </form>
          <p className="auth-footnote">
            La sesión y los permisos son validados por el backend.
          </p>
        </section>
      </div>
    </main>
  );
}
