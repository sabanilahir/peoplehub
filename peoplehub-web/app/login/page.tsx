import type { Metadata } from "next";
import { LoginForm } from "@/components/login-form";

export const metadata: Metadata = { title: "Masuk · PeopleHub" };

export default function LoginPage() {
  return (
    <main className="flex flex-1 items-center justify-center px-4 py-12">
      <div className="w-full max-w-sm">
        <div className="mb-8 text-center">
          <div className="mx-auto mb-4 flex h-12 w-12 items-center justify-center rounded-xl bg-accent text-lg font-bold text-accent-foreground">
            P
          </div>
          <h1 className="text-2xl font-semibold tracking-tight">PeopleHub</h1>
          <p className="mt-1 text-sm text-muted">
            Masuk untuk mengelola jadwal dan absensi
          </p>
        </div>

        <div className="rounded-2xl border border-border bg-surface p-6 shadow-sm sm:p-8">
          <LoginForm />
        </div>

        <p className="mt-6 text-center text-xs text-muted">
          Lupa password? Hubungi administrator HR.
        </p>
      </div>
    </main>
  );
}
