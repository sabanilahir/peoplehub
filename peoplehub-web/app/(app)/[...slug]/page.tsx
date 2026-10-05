// Halaman menu yang belum dibuat. Ganti dengan halaman nyata per rute.
export default async function ComingSoonPage({ params }: PageProps<"/[...slug]">) {
  const { slug } = await params;
  return (
    <div className="mx-auto max-w-xl rounded-xl border border-dashed border-border bg-surface p-10 text-center">
      <h1 className="text-lg font-semibold">Halaman sedang disiapkan</h1>
      <p className="mt-2 text-sm text-muted">
        /{slug.join("/")} belum tersedia di antarmuka. Datanya sudah bisa diakses lewat API.
      </p>
    </div>
  );
}
