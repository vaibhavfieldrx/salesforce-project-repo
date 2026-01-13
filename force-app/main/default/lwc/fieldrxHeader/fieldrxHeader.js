import { LightningElement, wire, track } from 'lwc';

import { NavigationMixin, CurrentPageReference } from 'lightning/navigation';

import { getContent } from 'experience/cmsDeliveryApi';
import FieldRxLogo from '@salesforce/resourceUrl/FieldRxLogo';

 
export default class FieldrxHeader extends NavigationMixin(LightningElement) {
 
    @track isMenuOpen = false;
    @track activeTab = 'Home';
 

    logoUrl = FieldRxLogo;
 

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
 
 

 
    get navClass() {

        return this.isMenuOpen ? 'nav open' : 'nav';

    }
 
    toggleMenu() {

        this.isMenuOpen = !this.isMenuOpen;

    }

@wire(CurrentPageReference)
    pageRef({ state }) {
        if (state && state.c__activeTab) {
            // If navigation passes a state param
            this.activeTab = state.c__activeTab;
        } else {
            // fallback: try to match URL with tab label
            const path = window.location.pathname.toLowerCase();
            const tab = this.tabsData.find(t => path.includes(t.label.toLowerCase()));
            this.activeTab = tab ? tab.label : 'Home';
        }
    }

    // Navigate when header tab is clicked
navigate(event) {
    const label = event.currentTarget.dataset.page;
    this.activeTab = label;

    const routeMap = {
        Home: '/',
        Customers: 'customers',
        Order: 'order',
        Products: 'product',
        Warehouse: 'warehouse',
        Inventory: 'inventory',
        Attendance: 'attendance',
        Reports: 'reports'
    };

    const url = routeMap[label];
    console.log("url", url)
    this[NavigationMixin.Navigate]({
        type: 'standard__webPage',
        attributes: { url }
    });
}

    // Compute CSS class for tabs
    get tabs() {
        return this.tabsData.map(tab => ({
            ...tab,
            cssClass: tab.label === this.activeTab ? 'nav-item active' : 'nav-item',
            tabClass:  tab.label === this.activeTab ? 'menu-icon active' : 'menu-icon'
        }));
    }
}