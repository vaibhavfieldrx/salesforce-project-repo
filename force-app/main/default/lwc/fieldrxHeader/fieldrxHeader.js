import { LightningElement, wire, track } from 'lwc';
import { NavigationMixin, CurrentPageReference } from 'lightning/navigation';
import getUserDepartment from '@salesforce/apex/UserContactController.getUserDepartment';
import FieldRxLogo from '@salesforce/resourceUrl/FieldRxLogo';

console.log('🔥 FieldrxHeader JS loaded');

export default class FieldrxHeader extends NavigationMixin(LightningElement) {

    @track isMenuOpen = false;
    @track activeTab = 'Home';
    @track department = '';
    @track filteredTabs = [];

    logoUrl = FieldRxLogo;

    // MASTER TAB LIST
    tabsData = [
        { label: 'Home', icon: 'utility:home', url: '/dashboard' },
        { label: 'Customers', icon: 'utility:user', url: '/customers' },
        { label: 'Order', icon: 'utility:cart', url: '/order' },
        { label: 'Products', icon: 'utility:product', url: '/products' },
        { label: 'Warehouse', icon: 'utility:home', url: '/warehouse' },
        { label: 'Inventory', icon: 'utility:chart', url: '/inventory' },
        { label: 'Attendance', icon: 'utility:event', url: '/attendance' },
        { label: 'Reports', icon: 'utility:chart', url: '/report' }
    ];

    // GET USER DEPARTMENT
    // @wire(getUserDepartment)
    // wiredDepartment({ data, error }) {
    //     console.log('🔥 wire fired');

    //     if (data) {
    //         console.log('✅ Department:', data);
    //         this.department = data;
    //         this.setTabsByDepartment();
    //     } else if (error) {
    //         console.error('❌ Apex error:', error);
    //     }
    // }

@wire(getUserDepartment)
wiredDepartment(response) {
    console.log('🔥 wire response =>', response);

    const { data, error } = response;

    if (data !== undefined) {
        console.log('✅ Department:', data);
        this.department = data;
        this.setTabsByDepartment();
    }

    if (error) {
        console.error('❌ Apex error:', error);
    }
}


    // FILTER TABS
    setTabsByDepartment() {

    // SM → ALL TABS
    if (this.department === 'SM') {
        this.filteredTabs = [...this.tabsData];
    } 
    
    // FE → ALL TABS
    else if (this.department === 'FE') {
        this.filteredTabs = [...this.tabsData];
    } 
    
    // OTHERS → ONLY HOME
    else {
        this.filteredTabs = this.tabsData.filter(tab => tab.label === 'Home');
    }

    // Detect active tab
    this.detectActiveTab();
}


    get navClass() {
        return this.isMenuOpen ? 'nav open' : 'nav';
    }

    toggleMenu() {
        this.isMenuOpen = !this.isMenuOpen;
    }

    @wire(CurrentPageReference)
    pageRef() {
        const path = window.location.pathname.toLowerCase();
        const tab = this.filteredTabs.find(t =>
            path.includes(t.label.toLowerCase())
        );
        this.activeTab = tab ? tab.label : 'Home';
    }

    navigate(event) {
        const label = event.currentTarget.dataset.page;
        this.activeTab = label;

        const tab = this.filteredTabs.find(t => t.label === label);
        if (tab) {
            this[NavigationMixin.Navigate]({
                type: 'standard__webPage',
                attributes: { url: tab.url }
            });
        }
    }

    get tabs() {
        return this.filteredTabs.map(tab => ({
            ...tab,
            cssClass: tab.label === this.activeTab ? 'nav-item active' : 'nav-item',
            tabClass: tab.label === this.activeTab ? 'menu-icon active' : 'menu-icon'
        }));
    }
}