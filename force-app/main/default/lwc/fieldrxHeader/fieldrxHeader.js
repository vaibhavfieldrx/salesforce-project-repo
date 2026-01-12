import { LightningElement, wire, track } from 'lwc';

import { NavigationMixin } from 'lightning/navigation';

import { getContent } from 'experience/cmsDeliveryApi';
 
export default class FieldrxHeader extends NavigationMixin(LightningElement) {
 
    @track isMenuOpen = false;

    activeTab = 'Dashboard';
 

    logoUrl;
 

    tabsData = [

        { label: 'Dashboard', icon: 'utility:home', url: '/dashboard' },

        { label: 'Customers', icon: 'utility:user', url: '/customers' },

        { label: 'Orders', icon: 'utility:cart', url: '/orders' },

        { label: 'Products', icon: 'utility:product', url: '/products' },

        { label: 'Warehouse', icon: 'utility:home', url: '/warehouse' },

        { label: 'Inventory', icon: 'utility:chart', url: '/inventory' },

        { label: 'Attendance', icon: 'utility:event', url: '/attendance' },

        { label: 'Reports', icon: 'utility:chart', url: '/report' }

    ];
 
    // ✅ CMS Image Fetch

    @wire(getContent, {

        contentId: 'MCDTJDQEZRNRE55B3XGBZFODUVIQ',

        channelOrSiteId: 'MCDTJDQEZRNRE55B3XGBZFODUVIQ'

    })

    wiredContent({ data, error }) {
console.log ('data', data);
        if (data) {

            this.logoUrl = data.contentNodes.source.url;

        }

        if (error) {

            console.error('CMS error', error);

        }

    }
 
    get tabs() {

        return this.tabsData.map(tab => ({

            ...tab,

            class: tab.label === this.activeTab ? 'nav-item active' : 'nav-item'

        }));

    }
 
    get navClass() {

        return this.isMenuOpen ? 'nav open' : 'nav';

    }
 
    toggleMenu() {

        this.isMenuOpen = !this.isMenuOpen;

    }
 
    navigate(event) {

        const url = event.currentTarget.dataset.url;

        this.activeTab = event.currentTarget.innerText.trim();

        this.isMenuOpen = false;
 
        this[NavigationMixin.Navigate]({

            type: 'standard__webPage',

            attributes: { url }

        });

    }

}