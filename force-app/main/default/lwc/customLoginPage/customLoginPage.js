import { LightningElement, track } from 'lwc';
import login from '@salesforce/apex/SiteLoginController.login';

export default class CustomLoginPage extends LightningElement {
    @track username;
    @track password;

    handleUsername(event) {
        this.username = event.target.value;
    }

    handlePassword(event) {
        this.password = event.target.value;
    }

    handleLogin() {
        login({ username: this.username, password: this.password })
            .then(() => {
                window.location.href = '/';
            })
            .catch(error => {
                console.error(error);
            });
    }
}