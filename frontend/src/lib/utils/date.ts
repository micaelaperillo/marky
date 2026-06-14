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

export function daysUntilStart(start?: string): number | null {
	if (!start) return null;
	const parsed = dayjs(start).startOf('day');
	if (!parsed.isValid()) return null;
	const today = dayjs().startOf('day');
	return Math.floor(parsed.diff(today, 'days'));
}

export type CampaignStatus = 'pending' | 'active' | 'ended';

export function campaignStatus(args: { start?: string; end?: string }): CampaignStatus {
	const today = dayjs().startOf('day');
	const start = args.start ? dayjs(args.start).startOf('day') : null;
	const end = args.end ? dayjs(args.end).startOf('day') : null;
	if (end && end.isValid() && end.isBefore(today)) return 'ended';
	if (start && start.isValid() && start.isAfter(today)) return 'pending';
	return 'active';
}
