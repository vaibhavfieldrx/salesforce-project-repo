import { LightningElement, wire, track, api } from 'lwc';
import getAllProducts from '@salesforce/apex/ProductController.getAllProducts';

export default class ProductSelector extends LightningElement {
    @track products = [];
    @track selectedProducts = [];
    @track paymentStatus = 'Pending';
    @track otpRequired = true;
    @track otp = '';
    @track previousOrders = [];
    totalRecords = 0;
    pageSize = 15;
    currentPage = 1;
    totalAmount = 0;
@track otpRequired = false;
@track showOtpModal = false;
@track otpArray = [
    { id: 'otp-0', value: '' },
    { id: 'otp-1', value: '' },
    { id: 'otp-2', value: '' },
    { id: 'otp-3', value: '' },
    { id: 'otp-4', value: '' },
    { id: 'otp-5', value: '' }
];

@track otp = '';

   @track showOtpModal = false;

    @api
    openOtpModal() {
        this.showOtpModal = true;
    }


    // ===== APEX =====
    @wire(getAllProducts, {
        pageSize: '$pageSize',
        pageNumber: '$currentPage'
    })
    wiredProducts({ data, error }) {
        if (data) {
            this.totalRecords = data.totalRecords;
            this.products = data.products.map(p => ({
                ...p,
                selected: this.isSelected(p.id)
            }));
        } else if (error) {
            console.error(error);
        }
    }

    // ===== PAGINATION =====
    get totalPages() { return Math.ceil(this.totalRecords / this.pageSize); }
    get isFirstPage() { return this.currentPage === 1; }
    get isLastPage() { return this.currentPage >= this.totalPages; }
    handleNext() { if (!this.isLastPage) this.currentPage++; }
    handlePrev() { if (!this.isFirstPage) this.currentPage--; }

    // ===== SELECT PRODUCT =====
    handleSelect(event) {
        const id = event.target.dataset.id;
        const checked = event.target.checked;

        if (checked) {
            const prod = this.products.find(p => p.id === id);
            this.selectedProducts.push({
                ...prod,
                qty: 1,
                subtotal: prod?.price || 0,
                discount: 0,
                displaySubtotal: prod?.price || 0
            });
        } else {
            this.selectedProducts = this.selectedProducts.filter(p => p.id !== id);
        }

        this.refreshSelection();
        this.calculateTotal();
    }

    // ===== QTY CHANGE =====
    handleQtyChange(event) {
        const id = event.target.dataset.id;
        const qty = parseInt(event.target.value, 10) || 1;

        this.selectedProducts = this.selectedProducts.map(p =>
            p.id === id
                ? { 
                    ...p, 
                    qty, 
                    subtotal: p.price * qty,
                    displaySubtotal: p.price * qty - (p.discount || 0)
                }
                : p
        );

        this.calculateTotal();
    }

    // ===== DISCOUNT CHANGE =====
    handleDiscountChange(event) {
        const id = event.target.dataset.id;
        const discount = parseFloat(event.target.value) || 0;

        this.selectedProducts = this.selectedProducts.map(p =>
            p.id === id
                ? { ...p, discount, displaySubtotal: p.subtotal - discount }
                : p
        );

        this.calculateTotal();
    }

    // ===== PAYMENT STATUS =====
    handlePaymentStatusChange(event) {
        this.paymentStatus = event.target.value;
    }

    // ===== OTP =====
    handleOtpChange(event) {
        this.otp = event.target.value;
    }
    verifyOtp() {
        if (this.otp === '123456') {
            this.otpRequired = false;
            alert('OTP Verified!');
        } else {
            alert('Invalid OTP');
        }
    }

handleOtpDigitChange(event) {
    const id = event.target.dataset.id;
    const value = event.target.value.replace(/\D/, '');
    this.otpArray = this.otpArray.map(d => d.id === id ? { ...d, value } : d);

    const index = this.otpArray.findIndex(d => d.id === id);
    if (value && index < this.otpArray.length - 1) {
        this.template.querySelectorAll('.otp-input')[index + 1].focus();
    }

    this.otp = this.otpArray.map(d => d.value).join('');
}

verifyAndCreateOrder() {
    if (this.otp.length === 6) {
        this.showOtpModal = false;
        this.createOrder();

        // Notify parent
        const event = new CustomEvent('verifyotp', { detail: this.otp });
        this.dispatchEvent(event);
    } else {
        alert('Enter complete 6-digit OTP.');
    }
}


closeOtpModal() {
    this.showOtpModal = false;
}

    // ===== TOTAL =====
    calculateTotal() {
        this.totalAmount = this.selectedProducts.reduce(
            (sum, p) => sum + (p.displaySubtotal || 0),
            0
        );
    }

    // ===== HELPERS =====
    isSelected(id) {
        return this.selectedProducts.some(p => p.id === id);
    }

    refreshSelection() {
        this.products = this.products.map(p => ({
            ...p,
            selected: this.isSelected(p.id)
        }));
    }

    handleRemoveItem(event) {
        const id = event.currentTarget.dataset.id;
        this.selectedProducts = this.selectedProducts.filter(p => p.id !== id);
        this.products = this.products.map(p =>
            p.id === id ? { ...p, selected: false } : p
        );
        this.calculateTotal();
    }

    // ===== LOAD PREVIOUS ORDERS =====
    loadPreviousOrders(customerId) {
        // Example dummy data
        this.previousOrders = [
            { id: '001', totalAmount: 250 },
            { id: '002', totalAmount: 480 }
        ];
    }
}
