import dayjs from 'dayjs';

export function fmt(d?: string): string {
	if (!d) return '—';
	const parsed = dayjs(d);
	if (!parsed.isValid()) return d;
	return parsed.toDate().toLocaleString(undefined, {
		day: 'numeric',
		month: 'short',
		year: 'numeric',
		hour: '2-digit',
		minute: '2-digit'
	});
}

export function daysLeft(end?: string): number | null {
	if (!end) return null;
	const parsed = dayjs(end);
	if (!parsed.isValid()) return null;
	const today = dayjs().startOf('day');
	return Math.floor(parsed.diff(today, 'days'));
}
