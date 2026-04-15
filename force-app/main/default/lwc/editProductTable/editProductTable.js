import { LightningElement, api, track } from 'lwc';

export default class EditProductTable extends LightningElement {
    @api
    oppName;
    @api
    selectedProducts = [];
    @track
    data = [];
    @api
    updatedProds = [];
    @api
    deletedProds = [];

    connectedCallback(){
        console.log('the selectedProducts');
        console.log(JSON.parse(JSON.stringify(this.selectedProducts)));

        let selectedProds = JSON.parse(JSON.stringify(this.selectedProducts));

        if(Array.isArray(selectedProds)){
            selectedProds.forEach(prod => {
                prod.ProductName = prod.Name.replace(this.oppName, '');
            });

            this.data = selectedProds;
        }
    }

    handleCellClick(event){
        let rowId = event.currentTarget.dataset.rowid;
        let field = event.currentTarget.dataset.field;

        console.log('rowId: '+rowId);

        let rowIndx = this.data.findIndex(row => row.Id == rowId);
        console.log('rowIndx: '+rowIndx);
        this.data[rowIndx]['show'+field.charAt(0).toUpperCase()+field.slice(1)+'Input'] = true;

        setTimeout(() => {
            let element = this.template.querySelector('lightning-input');
            element.focus();
        }, 5);
    }

    hideEditInput(event){
        let rowId = event.currentTarget.dataset.rowid;
        let field = event.currentTarget.dataset.field;

        let rowIndx = this.data.findIndex(row => row.Id == rowId);
        this.data[rowIndx]['show'+field.charAt(0).toUpperCase()+field.slice(1)+'Input'] = false;
    }

    handleRemove(event){
        let rowId = event.currentTarget.dataset.rowid;

        let rowIndx = this.data.findIndex(row => row.Id == rowId);
        this.deletedProds.push(this.data.splice(rowIndx, 1)[0]);
    }

    handleChange(event){
        let rowId = event.currentTarget.dataset.rowid;
        let field = event.currentTarget.dataset.field;

        let rowIndx = this.data.findIndex(row => row.Id == rowId);
        this.data[rowIndx][(field == 'unitprice' ? 'UnitPrice' : 'Quantity')] = event.currentTarget.value;
    }

    handleRemoveFocus(event){
        event.currentTarget.blur();
    }

    @api
    validate(){
        this.updatedProds = JSON.parse(JSON.stringify(this.data));
        this.updatedProds.forEach(updatedProd => {
            updatedProd.showQuantityInput = undefined;
            updatedProd.showUnitpriceInput = undefined;
            updatedProd.ProductName = undefined;
        });
    }
}