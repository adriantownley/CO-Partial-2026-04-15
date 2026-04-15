import { LightningElement, api, wire } from 'lwc';
import performAction from '@salesforce/apex/CreateQuoteLWCCtrl.performAction';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';

export default class CreateQuote extends LightningElement {
    isSpinner = false;
    _recordId;
    @api set recordId(value) {
        this._recordId = value;
        console.log('***recordId = ' + this._recordId);
        this.invokeApexCallout();
    }
    @api quoteRef;

    get recordId() {
        return this._recordId;
    }
    
    invokeApexCallout() {
        this.isSpinner = true;
        performAction({ recordId: this._recordId })
            .then(result => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'Success! Successfully created quote.',
                        variant: 'success',
                        mode: 'dismissable'
                    })
                );

                this.dispatchEvent(new CloseActionScreenEvent());
                this.isSpinner = false;
                this.redirectView();
            })
            .catch(error => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: 'Error! Process failed: ' + error.body.message,
                        variant: 'error',
                        mode: 'dismissable'
                    })
                );
                this.isSpinner = false;
            });
    }

    redirectView() {
        if(this.quoteRef){
            window.location.href = 'https://www.google.com/' + this.quoteRef // Redirect the browser to the URL
        }
    }
}