import { LightningElement, track } from 'lwc';
import getMyAttendance from '@salesforce/apex/AttendanceWiseController.getMyAttendance';
import getAllUsers from '@salesforce/apex/AttendanceWiseController.getAllUsers';

export default class MyAttendance extends LightningElement {

    @track viewType = 'MONTH';
    @track startDate;
    @track endDate;
    @track selectedMonth;
    @track selectedYear = new Date().getFullYear();

    @track groupedAttendance = [];
    @track presentCount = 0;

    @track tooltipVisible = false;
    @track tooltipStyle = '';
    @track tooltipData = { checkIn: '', checkOut: '' };

    viewOptions = [
        { label: 'Today', value: 'DAY' },
        { label: 'Month', value: 'MONTH' },
        { label: 'Year', value: 'YEAR' },
        { label: 'Custom', value: 'CUSTOM' }
    ];

    /* GETTERS */
    get showMonthPicker() { return this.viewType === 'MONTH'; }
    get showYearPicker() { return this.viewType === 'YEAR'; }
    get showCustomPicker() { return this.viewType === 'CUSTOM'; }

    connectedCallback() {
         this.checkAdminAndLoadUsers();
        this.setDefaultDates();
        this.fetchAttendance();
    }

     checkAdminAndLoadUsers(){
        getAllUsers()
        .then(result => {
            if(result.length > 0){
                this.isAdmin = true;
                this.users = result.map(u => ({ label: u.Name, value: u.Id }));
            }
        })
        .catch(err => console.error(err));
    }


      handleUserChange(e){
        this.selectedUserId = e.detail.value;
    }


    handleViewChange(e) { this.viewType = e.detail.value; this.setDefaultDates(); }
  handleMonthChange(e) {
    this.selectedMonth = e.target.value; // "YYYY-MM"

    if (!this.selectedMonth) return;

    const [year, month] = this.selectedMonth.split('-').map(Number);

    const first = new Date(year, month - 1, 1);
    const last = new Date(year, month, 0);

    this.startDate = this.formatLocalDate(first);
    this.endDate = this.formatLocalDate(last);
}

handleYearChange(e) {
     this.selectedYear = event.target.value.replace(/\D/g, '');

    if (this.viewType === 'YEAR') {
        const first = new Date(this.selectedYear, 0, 1);
        const last = new Date(this.selectedYear, 11, 31);

        this.startDate = this.formatLocalDate(first);
        this.endDate = this.formatLocalDate(last);
    }
}
    handleStartDateChange(e) { this.startDate = e.target.value; }
    handleEndDateChange(e) { this.endDate = e.target.value; }

    formatLocalDate(date) {
        const yyyy = date.getFullYear();
        const mm = String(date.getMonth() + 1).padStart(2, '0');
        const dd = String(date.getDate()).padStart(2, '0');
        return `${yyyy}-${mm}-${dd}`;
    }

    setDefaultDates() {
        const today = new Date();
        if(this.viewType === 'DAY'){
            const d = this.formatLocalDate(today);
            this.startDate = d; this.endDate = d;
        }
        if(this.viewType === 'MONTH'){
            const first = new Date(today.getFullYear(), today.getMonth(),1);
            const last = new Date(today.getFullYear(), today.getMonth()+1,0);
            this.startDate = this.formatLocalDate(first);
            this.endDate = this.formatLocalDate(last);
            this.selectedMonth = `${today.getFullYear()}-${String(today.getMonth()+1).padStart(2,'0')}`;
        }
        if(this.viewType === 'YEAR'){
            const first = new Date(this.selectedYear,0,1);
            const last = new Date(this.selectedYear,11,31);
            this.startDate = this.formatLocalDate(first);
            this.endDate = this.formatLocalDate(last);
        }
    }

    fetchAttendance(){
        if(!this.startDate || !this.endDate) return;
        getMyAttendance({ 
            startDate: this.startDate, 
            endDate: this.endDate, 
            selectedUserId: this.selectedUserId 
        })
        .then(result => this.processAttendance(result))
        .catch(err => console.error(err));
    }

    processAttendance(data){
        const present = data.filter(d => d.isPresent);
        this.presentCount = present.length;

        const grouped = {};

        present.forEach(rec => {
            const dateObj = new Date(rec.attendanceDate);
            const monthKey = dateObj.toLocaleString('default',{month:'long',year:'numeric'});
            if(!grouped[monthKey]) grouped[monthKey]=[];
            grouped[monthKey].push({
                day: dateObj.toLocaleString('default',{weekday:'short'}),
                date: dateObj.getDate(),
                checkIn: rec.checkInTime || '--:--',
                checkOut: rec.checkOutTime || '--:--'
            });
        });

        this.groupedAttendance = Object.keys(grouped).map(m=>({
            month:m, days: grouped[m]
        }));
    }

    /* ===================== TOOLTIP ===================== */
    showTooltip(e){
        const el = e.currentTarget;
        const rect = el.getBoundingClientRect();
        this.tooltipData = {
            checkIn: el.dataset.checkin,
            checkOut: el.dataset.checkout
        };
        this.tooltipStyle = `position: fixed; top: ${rect.bottom + 5}px; left: ${rect.left}px; background: #fff; border: 1px solid #ccc; padding: 6px 10px; z-index: 99; border-radius: 4px; box-shadow: 0 2px 6px rgba(0,0,0,0.15);`;
        this.tooltipVisible = true;
    }

    hideTooltip(){
        this.tooltipVisible = false;
    }
}