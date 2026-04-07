import type { Dayjs } from 'dayjs';

export default function iso(date: Dayjs) {
	return date.format('YYYY-MM-DD');
}
