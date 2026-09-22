export default function AccountLoading() {
  return (
    <div className="space-y-6" aria-busy="true" aria-label="Chargement">
      <div className="flex items-center gap-4">
        <div className="skeleton h-12 w-12 !rounded-2xl" />
        <div className="space-y-2">
          <div className="skeleton h-7 w-44" />
          <div className="skeleton h-4 w-56" />
        </div>
      </div>
      <div className="skeleton h-10 w-full max-w-md !rounded-full" />
      <div className="grid gap-3 md:grid-cols-2">
        <div className="skeleton h-40" />
        <div className="skeleton h-40" />
      </div>
    </div>
  );
}
