import { LightningElement, wire } from 'lwc';
import getFEAttendance from '@salesforce/apex/AttendanceController.getFEAttendance';

export default class AttendanceList extends LightningElement {

    attendanceRecords = [];
    error;

    // Wire Apex (keeping selectedDate as in your Apex)
    @wire(getFEAttendance, { selectedDate: null })
    wiredAttendance({ error, data }) {

        console.log('Attendance Data:', data);

        if (data) {

            // ---------- THIS WEEK FILTER ----------
            const today = new Date();
            today.setHours(0, 0, 0, 0);

            // Last 7 days (including today)
           // ---------- THIS WEEK (MON-SUN) ----------

// Monday
const weekStart = new Date(today);
weekStart.setDate(today.getDate() - today.getDay() + 1);
weekStart.setHours(0, 0, 0, 0);

// Sunday
const weekEnd = new Date(weekStart);
weekEnd.setDate(weekStart.getDate() + 6);
weekEnd.setHours(23, 59, 59, 999);
// ---------------------------------------

            // -------------------------------------

            this.attendanceRecords = data

                // ✅ FILTER ONLY THIS WEEK
                .filter(rec => {

                    if (!rec.checkIn) return false;

                    const checkInDate = new Date(rec.checkIn);
                    checkInDate.setHours(0, 0, 0, 0);

                    return (
    checkInDate >= weekStart &&
    checkInDate <= weekEnd
);
                })

                // ---------- YOUR EXISTING LOGIC ----------
                .map((rec, index) => {

                    let statusText = rec.status || 'Absent';
                    let isActive = false;

                    // If CheckIn + CheckOut
                    if (rec.checkIn && rec.checkOut) {

                        const checkIn = new Date(rec.checkIn);
                        const checkOut = new Date(rec.checkOut);

                        if (checkOut >= checkIn) {

                            const diffMs = checkOut - checkIn;
                            const totalMinutes = Math.floor(diffMs / 60000);

                            const hours = Math.floor(totalMinutes / 60);
                            const minutes = totalMinutes % 60;

                            statusText = `${hours}h ${minutes}m`;
                        } else {

                            // Invalid time
                            statusText = '--';
                        }
                    }

                    // Only CheckIn (Active)
                    else if (rec.checkIn && !rec.checkOut) {

                        statusText = 'Active';
                        isActive = true;
                    }

                    return {

                        // Unique key
                        id: rec.userId + index,

                        // Date
                        day: rec.checkIn
                            ? new Date(rec.checkIn).toLocaleDateString('en-IN', {
                                  day: '2-digit',
                                  month: 'short',
                                  year: 'numeric'
                              })
                            : 'N/A',

                        // Time
                        time: rec.checkIn
                            ? this.formatTime(rec.checkIn, rec.checkOut)
                            : '--',

                        // Status
                        status: statusText,

                        // For Icon
                        isActive: isActive
                    };
                });

            this.error = undefined;

        } else if (error) {

            console.error('Error:', error);

            this.error = error;
            this.attendanceRecords = [];
        }
    }

    // ---------- Helper: Format Time ----------
    formatTime(checkIn, checkOut) {

        const format = (time) =>
            new Date(time).toLocaleTimeString([], {
                hour: '2-digit',
                minute: '2-digit'
            });

        return `${format(checkIn)} - ${checkOut ? format(checkOut) : '--'}`;
    }
}