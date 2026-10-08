import { Button } from "./Button";

export function Pagination({
  page,
  pages,
  total,
  onChange,
}: {
  page: number;
  pages: number;
  total: number;
  onChange: (page: number) => void;
}) {
  if (pages <= 1) return null;

  return (
    <div className="flex items-center justify-between border-t border-white/10 px-4 py-3 text-sm text-slate-300">
      <span>
        Page {page} of {pages} &middot; {total} total
      </span>
      <div className="flex gap-2">
        <Button
          variant="ghost"
          className="px-3 py-1.5"
          disabled={page <= 1}
          onClick={() => onChange(page - 1)}
        >
          Previous
        </Button>
        <Button
          variant="ghost"
          className="px-3 py-1.5"
          disabled={page >= pages}
          onClick={() => onChange(page + 1)}
        >
          Next
        </Button>
      </div>
    </div>
  );
}
