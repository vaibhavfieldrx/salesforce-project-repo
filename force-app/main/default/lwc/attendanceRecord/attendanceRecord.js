import { LightningElement, wire, track } from 'lwc';
import getFEAttendance from '@salesforce/apex/AttendanceController.getFEAttendance';

export default class AttendanceRecord extends LightningElement {

    // ---------------- FILTERS ----------------
    selectedStatus = 'All';
    searchKey = '';

    statusOptions = [
        { label: 'All', value: 'All' },
        { label: 'Present', value: 'Present' },
        { label: 'Absent', value: 'Absent' },
        { label: 'Late', value: 'Late' }
    ];

    // ---------------- DATA ----------------
    @track fullData = [];
    @track attendanceList = [];

    // ---------------- PAGINATION ----------------
    pageSize = 5;
    pageNumber = 1;
    totalPages = 1;

    // ---------------- SUMMARY ----------------
    presentCount = 0;
    absentCount = 0;

    // ---------------- DATA LOAD ----------------
    @wire(getFEAttendance)
    wiredAttendance({ data, error }) {
        if (data) {
            this.fullData = data.map(rec => ({
                id: rec.userId,
                name: rec.userName,
                initial: rec.userName ? rec.userName.charAt(0).toUpperCase() : '',
                role: rec.role || 'NA',
                department: rec.department || 'NA',
                checkIn: rec.checkIn ? rec.checkIn.split('T')[0] : 'NA',
                checkOut: rec.checkOut ? rec.checkOut.split('T')[0] : 'NA',
                status: rec.status,
                statusClass: this.getStatusClass(rec.status)
            }));

            this.pageNumber = 1;
            this.applyFilters();
        } else if (error) {
            console.error(error);
        }
    }

    // ---------------- FILTER HANDLERS ----------------
    handleStatusChange(event) {
        this.selectedStatus = event.detail.value;
        this.pageNumber = 1;
        this.applyFilters();
    }

    handleSearch(event) {
        this.searchKey = event.target.value.toLowerCase();
        this.pageNumber = 1;
        this.applyFilters();
    }

    // ---------------- MAIN LOGIC ----------------
    applyFilters() {
        let filtered = [...this.fullData];

        // 🔹 Status filter
        if (this.selectedStatus !== 'All') {
            filtered = filtered.filter(
                row => row.status === this.selectedStatus
            );
        }

        // 🔹 Search filter
        if (this.searchKey) {
            filtered = filtered.filter(
                row => row.name?.toLowerCase().includes(this.searchKey)
            );
        }

        // 🔹 Summary
        this.calculateSummary(filtered);

        // 🔹 Pagination
        this.totalPages = Math.ceil(filtered.length / this.pageSize) || 1;

        const start = (this.pageNumber - 1) * this.pageSize;
        this.attendanceList = filtered.slice(start, start + this.pageSize);
    }

    calculateSummary(data) {
    this.presentCount = data.filter(r => r.status === 'Present').length;
    this.absentCount = data.filter(r => r.status === 'Absent').length;
}


    getStatusClass(status) {
        if (status === 'Present') return 'status-present';
        if (status === 'Absent') return 'status-absent';
        return 'status-late';
    }

    // ---------------- PAGINATION ----------------
    get isFirstPage() {
        return this.pageNumber === 1;
    }

    get isLastPage() {
        return this.pageNumber === this.totalPages;
    }

    get currentPage() {
        return this.pageNumber;
    }

    nextPage() {
        if (this.pageNumber < this.totalPages) {
            this.pageNumber++;
            this.applyFilters();
        }
    }

    prevPage() {
        if (this.pageNumber > 1) {
            this.pageNumber--;
            this.applyFilters();
        }
    }
}
