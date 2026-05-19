import dayjs from 'dayjs';

export function fmt(d?: string): string {
	if (!d) return '—';
	const parsed = dayjs(d);
	if (!parsed.isValid()) return d;
	return parsed.toDate().toLocaleDateString(undefined, {
		day: 'numeric',
		month: 'short',
		year: 'numeric'
	});
}

export function daysLeft(end?: string): number | null {
	if (!end) return null;
	const parsed = dayjs(end);
	if (!parsed.isValid()) return null;
	const today = dayjs().startOf('day');
	return Math.floor(parsed.diff(today, 'days'));
}
