import { LightningElement, wire, track } from 'lwc';
import getFEAttendance from '@salesforce/apex/AttendanceController.getFEAttendance';

export default class AttendanceRecord extends LightningElement {

    // Filters
    selectedDate = new Date().toISOString().split('T')[0];
    searchKey = '';

    // Data
    @track fullData = [];
    @track attendanceList = [];

    // Pagination
    pageSize = 5;
    pageNumber = 1;
    totalPages = 0;

    // Summary
    presentCount = 0;
    absentCount = 0;
    attendanceRate = 0;

    @wire(getFEAttendance, { selectedDate: '$selectedDate' })
    wiredAttendance({ data, error }) {
        if (data) {
         this.fullData = data.map(rec => ({
    id: rec.userId,
    name: rec.userName,
    initial: rec.userName ? rec.userName.charAt(0).toUpperCase() : '',
    role: rec.role ? rec.role : "NA",
    department: rec.department ? rec.department : "NA",
    checkIn: rec.checkIn?.split("T")[0] ? rec.checkIn?.split("T")[0] : "NA",
    checkOut: rec.checkOut?.split("T")[0] ? rec.checkOut?.split("T")[0] : "NA",
    status: rec.status,
    statusClass: this.getStatusClass(rec.status)
}));

            this.pageNumber = 1;
            this.applyFilters();
        } else if (error) {
            console.error(error);
        }
    }

    // ---------- Filters ----------
    handleSearch(event) {
        this.searchKey = event.target.value.toLowerCase();
        this.applyFilters();
    }

    handleDateChange(event) {
        this.selectedDate = event.target.value;
        this.pageNumber = 1;
    }

    // ---------- Logic ----------
    applyFilters() {
        const filtered = this.fullData.filter(row =>
            row.name?.toLowerCase().includes(this.searchKey)
        );

        this.calculateSummary(filtered);

        this.totalPages = Math.ceil(filtered.length / this.pageSize);
        const start = (this.pageNumber - 1) * this.pageSize;
        this.attendanceList = filtered.slice(start, start + this.pageSize);
    }

    calculateSummary(data) {
        this.presentCount = data.filter(r => r.status === 'Present').length;
        this.absentCount = data.filter(r => r.status === 'Absent').length;

        const total = data.length;
        this.attendanceRate = total
            ? Math.round((this.presentCount / total) * 100)
            : 0;
    }

    getStatusClass(status) {
        if (status === 'Present') return 'status-present';
        if (status === 'Absent') return 'status-absent';
        return 'status-late';
    }

    // ---------- Pagination ----------
    get paginationList() {
        return Array.from({ length: this.totalPages }, (_, i) => {
            const page = i + 1;
            return {
                number: page,
                className: page === this.pageNumber ? 'page-btn active' : 'page-btn'
            };
        });
    }

    handlePageClick(event) {
        this.pageNumber = Number(event.target.dataset.page);
        this.applyFilters();
    }

    handleNext() {
        if (this.pageNumber < this.totalPages) {
            this.pageNumber++;
            this.applyFilters();
        }
    }

    handlePrevious() {
        if (this.pageNumber > 1) {
            this.pageNumber--;
            this.applyFilters();
        }
    }

    get disablePrevious() {
        return this.pageNumber === 1;
    }

    get disableNext() {
        return this.pageNumber === this.totalPages;
    }
}
