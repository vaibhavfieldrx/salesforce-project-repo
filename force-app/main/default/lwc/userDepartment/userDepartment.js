import { LightningElement, wire } from 'lwc';
import getUserDepartment from '@salesforce/apex/UserContactController.getUserDepartment';

export default class UserDepartment extends LightningElement {
    department;

    @wire(getUserDepartment)
    wiredDept({ data }) {
        if (data) {
            this.department = data;
            this.dispatchEvent(
                new CustomEvent('department', {
                    detail: this.department
                })
            );
        }
    }
}
