import { LightningElement, track, wire } from 'lwc';
import ProductModal from 'c/productSelectorModal';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getProducts from '@salesforce/apex/ProductController.getProducts';
import createOrderWithItems from '@salesforce/apex/OrderController.createOrderWithItems';
import getOrderHistory from '@salesforce/apex/OrderController.getOrderHistory';
import getOrderForEdit from '@salesforce/apex/OrderController.getOrderForEdit';
import { NavigationMixin, CurrentPageReference } from 'lightning/navigation';
import LightningAlert from 'lightning/alert';
import updateOrderWithItems
    from '@salesforce/apex/OrderController.updateOrderWithItems';

export default class NewOrderForm extends NavigationMixin(LightningElement) {

    /* ===================== MODE ===================== */
    mode = 'create'; // create | edit
    orderId;
@track orderData;
    /* ===================== STATE ===================== */
    customerId;
    selectedCustomer;

    @track products = [];
    orderProducts = [];
    orderTotal = 0;

    total = 0;
    discount = 0;
    paymentStatus = 'Pending';

    @track orders = [];
    @track totalRecords = 0;
    @track pageNumber = 1;
    @track pages = [];
    pageSize = 5;
    isLoading = false;

    @track otpRequired = false;
    @track showOtpModal = false;

    orderAddressData = {};

    /* ===================== PAGINATION ===================== */
    get totalPages() {
        return Math.ceil(this.totalRecords / this.pageSize) || 1;
    }
    get isFirstPage() {
        return this.pageNumber === 1;
    }
    get isLastPage() {
        return this.pageNumber === this.totalPages;
    }

    /* ===================== ROUTING ===================== */
    @wire(CurrentPageReference)
    getPageParams(pageRef) {
        if (!pageRef) return;

        this.mode = pageRef.state?.c__mode || 'create';
        this.orderId = pageRef.state?.c__orderId;
        console.log("pageRef.state?.c__orderId", pageRef.state?.c__orderId)
        if (this.mode === 'edit' && this.orderId) {
            this.loadOrderForEdit();
        }
    }

    get hasOrders() {
    return this.orders && this.orders.length > 0;
}

openOrderModal(){
    this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: '/order'
            }
        });
}
async loadOrderHistory() {
    if (!this.customerId) return;

    try {
        this.isLoading = true;

        const result = await getOrderHistory({
            accountId: this.customerId,
            pageSize: this.pageSize,
            pageNumber: this.pageNumber
        });

       this.orders = (result.orders || []).map(order => ({
    ...order,
    statusClass: this.getStatusClass(order.Status)
}));
        this.totalRecords = result.totalRecords || 0;
        this.updatePages();

    } catch (error) {
        console.error('Order history error', error);
    } finally {
        this.isLoading = false;
    }
}

    updatePages() {
        this.pages = Array.from({ length: this.totalPages }, (_, i) => {
            const number = i + 1;
            return {
                number,
                class: number === this.pageNumber ? 'page active' : 'page'
            };
        });
    }

    /* ===================== CUSTOMER ===================== */
    handleCustomer(event) {
        this.selectedCustomer = event.detail;
        this.customerId = event.detail.accountId;
        this.pageNumber = 1;
        this.isLoading = true;
    }

    /* ===================== ALERT ===================== */
    async showAlert(title, message, theme) {
        await LightningAlert.open({
            label: title,
            message,
            theme
        });
    }

    /* ===================== PRODUCTS ===================== */
    async openProductModal() {
        const selectedProducts = await ProductModal.open({ size: 'large' });
        if (selectedProducts?.length) {
            this.handleProductsSelected({ detail: selectedProducts });
        }
    }

    async handleProductsSelected(event) {
        const { products, totalAmount, paymentStatus } = event.detail;

        this.orderProducts = products;
        this.orderTotal = totalAmount;
        this.paymentStatus = paymentStatus;

        const productIds = products.map(p => p.productId);
        const priceData = await getProducts({ productIds });

        this.products = products.map(p => {
            const priceObj = priceData.find(r => r.id === p.Id);
            return {
                id: p.productId,
                name: p.Name,
                price: priceObj ? priceObj.price : p.unitPrice,
                qty: p.quantity,
                discount: p.discount,
            };
        });

        this.calculateTotal();
    }

    handleQtyChange(e) {
        const id = e.target.dataset.id;
        const qty = parseInt(e.target.value, 10) || 1;

        this.products = this.products.map(p => {
            if (p.id === id) p.qty = qty;
            return p;   
        });

        this.calculateTotal();
    }

    calculateTotal() {
        this.total = this.products.reduce(
            (sum, p) => sum + (p.price * p.qty), 0
        );
    }

    /* ===================== ADDRESS ===================== */
    handleAddressChange(event) {
        const { billingAddress, shippingAddress, warehouseId } = event.detail;
        this.orderAddressData = { billingAddress, shippingAddress, warehouseId };
    }

    /* ===================== OTP ===================== */
    handleOtpRequiredChange(event) {
        this.otpRequired = event.target.checked;
    }

    handleCreateOrder() {
        if (this.otpRequired) {
            this.showOtpModal = true;
        } else {
        this.mode === 'edit'
            ? this.updateOrder()
            : this.createOrder();
    
            // this.createOrder();
        }
    }

    handleVerifyOtp() {
        this.showOtpModal = false;
        this.createOrder();
    }

    handleCloseOtp() {
        this.showOtpModal = false;
    }

    /* ===================== CREATE (UNCHANGED) ===================== */
    createOrder() {
        if (!this.selectedCustomer?.accountId) {
            this.showAlert('Error', 'Select a customer first', 'error');
            return;
        }

        if (!this.orderProducts?.length) {
            this.showAlert('Error', 'Select at least one product', 'error');
            return;
        }

        const payload = {
            accountId: this.selectedCustomer.accountId,
            billToContactId: this.selectedCustomer.contactId,
            billingAddress: this.orderAddressData.billingAddress,
            shippingAddress: this.orderAddressData.shippingAddress,
            warehouseId: this.orderAddressData.warehouseId,
            paymentStatus: this.paymentStatus,
            totalAmount: this.orderTotal,
            products: this.orderProducts,
            discount: this.discount,
            discountAmount: this.orderTotal,
        };

        createOrderWithItems({ orderJson: JSON.stringify(payload) })
            .then(() => this.showCreateSuccess())
            .catch(err =>
                this.showAlert('Error', err?.body?.message, 'error')
            );
    }

    async showCreateSuccess() {
        await LightningAlert.open({
            label: 'Success',
            message: 'Order Created Successfully',
            theme: 'success'
        });
        window.location.reload();
    }

    /* ===================== EDIT ===================== */
  async loadOrderForEdit() {
    try {
        const data = await getOrderForEdit({ orderId: this.orderId });

        this.customerId = data.accountId;
        this.selectedCustomer = { accountId: data.accountId };

        this.orderAddressData = {
            billingAddress: data.billingAddress,
            shippingAddress: data.shippingAddress,
            warehouseId: data.warehouseId
        };

        setTimeout(() => {
            const productCmp = this.template.querySelector('c-product-selector');
            if (productCmp) {
                productCmp.setEditProducts(data.products);
            }
        }, 0);

        this.calculateTotal();

        // ✅ SAFE HISTORY LOAD
        this.pageNumber = 1;
        this.loadOrderHistory();

    } catch (e) {
        console.error(e);
        this.showAlert('Error', 'Failed to load order', 'error');
    }
}
    get isEditMode() {
    return this.mode === 'edit';
}

 updateOrder() {
    const payload = {
        orderId: this.orderId,
        totalAmount: this.total,
        discount: this.discount,
        discountAmount: this.orderTotal,
        paymentStatus: this.paymentStatus,
        warehouseId: this.orderAddressData.warehouseId,
        billToContactId: this.selectedCustomer.contactId,
        billingAddress: this.orderAddressData.billingAddress,
        shippingAddress: this.orderAddressData.shippingAddress,

        products: this.products.map(p => ({
            productId: p.id,
            quantity: p.qty,
            unitPrice: p.price,
            discount: p.discount || 0
        }))
    };

    updateOrderWithItems({ orderJson: JSON.stringify(payload) })
        .then(() => this.showUpdateSuccess())
        .catch(err =>
            this.showAlert(
                'Error',
                err?.body?.message || 'Update failed',
                'error'
            )
        );
}


    getStatusClass(status) {
    if (!status) return 'status-default';

    switch (status.toLowerCase()) {
        case 'draft':
            return 'status-draft';
        case 'completed':
            return 'status-completed';
        case 'pending':
            return 'status-pending';
        case 'cancelled':
            return 'status-cancelled';
        default:
            return 'status-default';
    }
}

    async showUpdateSuccess() {
        await LightningAlert.open({
            label: 'Success',
            message: 'Order Updated Successfully',
            theme: 'success'
        });
        window.location.reload();
    }

    /* ===================== SAVE ===================== */
   


    handlePrev() {
    if (this.isFirstPage) return;
    this.pageNumber--;
    this.loadOrderHistory();
}

handleNext() {
    if (this.isLastPage) return;
    this.pageNumber++;
    this.loadOrderHistory();
}

goToPage(event) {
    const page = Number(event.target.dataset.page);
    if (page === this.pageNumber) return;
    this.pageNumber = page;
    this.loadOrderHistory();
}
}

