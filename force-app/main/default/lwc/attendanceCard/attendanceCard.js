import { LightningElement, wire, track } from 'lwc';
import getAttendanceData from '@salesforce/apex/AttendanceCardController.getAttendanceData';

export default class AttendanceCard extends LightningElement {
    @track attendanceList = [];

    @wire(getAttendanceData)
    wiredData({ data, error }) {
        if (data) {
            const startOfWeek = this.getStartOfWeek();
            const endOfWeek = this.getEndOfWeek();

            this.attendanceList = data
                .filter(r => {
                    const checkInDate = new Date(r.Check_in_Time__c);
                    return checkInDate >= startOfWeek && checkInDate <= endOfWeek;
                })
                .map(r => {
                    const checkIn = r.Check_in_Time__c;
                    const checkOut = r.Check_out_Time__c;

                    let hoursText = 'Active';
                    let statusClass = 'active';

                    if (checkIn && checkOut) {
                        const diff = this.calculateHours(checkIn, checkOut);
                        hoursText = `${diff.h}h ${diff.m}m`;
                        statusClass = 'normal';
                    }

                    return {
                        id: r.Id,
                        date: this.formatDate(checkIn),
                        time: this.formatTimeRange(checkIn, checkOut),
                        hours: hoursText,
                        statusClass
                    };
                });
        }
    }

    getStartOfWeek() {
        const today = new Date();
        const day = today.getDay(); // 0 = Sunday
        const diff = today.getDate() - day + (day === 0 ? -6 : 1); // Monday
        return new Date(today.setDate(diff));
    }

    getEndOfWeek() {
        const start = this.getStartOfWeek();
        return new Date(start.getFullYear(), start.getMonth(), start.getDate() + 6, 23, 59, 59);
    }

    formatDate(dt) {
        return new Date(dt).toLocaleDateString('en-US', {
            weekday: 'short',
            month: 'short',
            day: 'numeric'
        });
    }

    formatTime(dt) {
        return new Date(dt).toLocaleTimeString('en-US', {
            hour: '2-digit',
            minute: '2-digit',
            hour12: true
        });
    }

    formatTimeRange(inTime, outTime) {
        return outTime
            ? `${this.formatTime(inTime)} - ${this.formatTime(outTime)}`
            : `${this.formatTime(inTime)} --`;
    }

    calculateHours(start, end) {
        const diffMs = new Date(end) - new Date(start);
        const h = Math.floor(diffMs / (1000 * 60 * 60));
        const m = Math.floor((diffMs / (1000 * 60)) % 60);
        return { h, m };
    }
}
