import { request } from './request'

export function getSystemStatus() {
	return request('/system/status')
}
