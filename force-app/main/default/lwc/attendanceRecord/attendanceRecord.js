import { LightningElement, wire } from 'lwc';
import getFEAttendance from '@salesforce/apex/AttendanceController.getFEAttendance';

export default class AttendanceRecord extends LightningElement {

    fullData = [];
    attendanceList = [];

    pageSize = 5;
    pageNumber = 1;
    totalPages = 0;

    @wire(getFEAttendance)
    wiredAttendance({ data, error }) {
        if (data) {
            // Add statusClass for styling
            this.fullData = data.map(record => {
                return {
                    ...record,
                    statusClass: this.getStatusClass(record.Status__c)
                };
            });

            this.totalPages = Math.ceil(this.fullData.length / this.pageSize);
            this.updatePageData();
        } else if (error) {
            console.error('Error fetching attendance:', error);
        }
    }

    getStatusClass(status) {
        switch (status) {
            case 'Present':
                return 'status-present';
            case 'Absent':
                return 'status-absent';
            case 'Late':
                return 'status-late';
            default:
                return '';
        }
    }

    updatePageData() {
        const start = (this.pageNumber - 1) * this.pageSize;
        const end = start + this.pageSize;
        this.attendanceList = this.fullData.slice(start, end);
    }

    handleNext() {
        if (this.pageNumber < this.totalPages) {
            this.pageNumber++;
            this.updatePageData();
        }
    }

    handlePrevious() {
        if (this.pageNumber > 1) {
            this.pageNumber--;
            this.updatePageData();
        }
    }

    get disablePrevious() {
        return this.pageNumber === 1;
    }

    get disableNext() {
        return this.pageNumber === this.totalPages;
    }
}