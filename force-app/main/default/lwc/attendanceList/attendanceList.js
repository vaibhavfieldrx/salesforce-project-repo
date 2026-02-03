import { LightningElement, track, wire } from 'lwc';
import getFEAttendance from '@salesforce/apex/AttendanceController.getFEAttendance';

export default class AttendanceList extends LightningElement {
    @track attendanceRecords = [];
    @track error;

    @wire(getFEAttendance, { selectedDate: null })
wiredAttendance({ error, data }) {
    if (data) {
        const today = new Date();
        today.setHours(0, 0, 0, 0);

        const sevenDaysAgo = new Date(today);
        sevenDaysAgo.setDate(today.getDate() - 6); // last 7 days incl today

        this.attendanceRecords = data
            .filter(rec => {
                if (!rec.checkIn) return false;

                const checkInDate = new Date(rec.checkIn);
                checkInDate.setHours(0, 0, 0, 0);

                return checkInDate >= sevenDaysAgo && checkInDate <= today;
            })
           .map((rec, index) => {
    let statusText = 'Absent';

if (rec.checkIn && rec.checkOut) {
    const checkIn = new Date(rec.checkIn);
    const checkOut = new Date(rec.checkOut);

    if (checkOut >= checkIn) {
        const diffMs = checkOut - checkIn;
        const totalMinutes = Math.floor(diffMs / (1000 * 60));

        const hours = Math.floor(totalMinutes / 60);
        const minutes = totalMinutes % 60;

        statusText = `${hours}h ${minutes}m`;
    } else {
        // ❗ invalid or wrong time order
        statusText = '--';
    }
} else if (rec.checkIn && !rec.checkOut) {
    statusText = 'Active';
}



    return {
        id: rec.userId + index,
        day: rec.checkIn ? new Date(rec.checkIn).toDateString() : 'N/A',
        time: rec.checkIn
            ? `${new Date(rec.checkIn).toLocaleTimeString([], {
                  hour: '2-digit',
                  minute: '2-digit'
              })} - ${
                  rec.checkOut
                      ? new Date(rec.checkOut).toLocaleTimeString([], {
                            hour: '2-digit',
                            minute: '2-digit'
                        })
                      : '--'
              }`
            : '--',
        status: statusText,
        statusClass: statusText === 'Active' ? 'active' : 'present'
    };
});


        this.error = undefined;
    } else if (error) {
        this.error = error;
        this.attendanceRecords = [];
    }
}

}
