// All data in this prototype is dummy. Amounts are in rupees.
const DATA = {
  user: { name: 'Sankar', household: 'XYZ' },
  balance: 84250.5,
  earning: 120000,
  spend: 35749.5,
  cards: [
    { id: 'hdfc', bank: 'HDFC Bank', type: 'Credit', network: 'Visa', last4: '4821', holder: 'SANKAR PK', exp: '09/29', limit: 200000, used: 46500, due: '05 Nov', statement: '18 Oct', color: 'blue', full: '4532 7781 0092 4821' },
    { id: 'sbi', bank: 'SBI', type: 'Debit', network: 'RuPay', last4: '1190', holder: 'SANKAR PK', exp: '02/28', color: 'dark', full: '6521 0043 8877 1190' },
    { id: 'icici', bank: 'ICICI Bank', type: 'Credit', network: 'Mastercard', last4: '7305', holder: 'SANKAR PK', exp: '12/27', limit: 100000, used: 12800, due: '12 Nov', statement: '25 Oct', color: 'violet', full: '5412 3390 6618 7305' },
  ],
  categories: [
    { name: 'Food', amount: 11240, color: '#fbbf24', icon: 'food' },
    { name: 'Shopping', amount: 9480, color: '#6d8ff7', icon: 'bag' },
    { name: 'Bills', amount: 8420, color: '#2f3b52', icon: 'doc' },
    { name: 'Travel', amount: 4120, color: '#5ad0f5', icon: 'car' },
    { name: 'Other', amount: 2489.5, color: '#a89cf0', icon: 'dots' },
  ],
  week: [
    { d: 17, l: 'MON', v: 62 }, { d: 18, l: 'TUE', v: 30 }, { d: 19, l: 'WED', v: 40 },
    { d: 20, l: 'THU', v: 88 }, { d: 21, l: 'FRI', v: 55 }, { d: 22, l: 'SAT', v: 24 }, { d: 23, l: 'SUN', v: 58 },
  ],
  txns: [
    { id: 1, m: 'Swiggy', sub: 'UPI · HDFC •4821', amt: -480, cat: 'Food', date: 'Today', icon: 'food', tone: 'orange' },
    { id: 2, m: 'Amazon', sub: 'Card · ICICI •7305', amt: -2499, cat: 'Shopping', date: 'Today', icon: 'bag', tone: 'violet' },
    { id: 3, m: 'Salary - Acme Pvt Ltd', sub: 'NEFT · SBI •1190', amt: 120000, cat: 'Income', date: 'Yesterday', icon: 'wallet', tone: 'green' },
    { id: 4, m: 'Raju Stores', sub: 'UPI · needs a category', amt: -480, cat: '?', date: 'Yesterday', icon: 'question', tone: 'red', ask: true },
    { id: 5, m: 'Uber', sub: 'UPI · SBI •1190', amt: -312, cat: 'Travel', date: '21 Oct', icon: 'car', tone: 'blue' },
    { id: 6, m: 'BESCOM Electricity', sub: 'Bill pay · SBI •1190', amt: -1840, cat: 'Bills', date: '20 Oct', icon: 'doc', tone: 'orange' },
    { id: 7, m: 'Transfer to own account', sub: 'Possible self transfer', amt: -15000, cat: 'Transfer', date: '19 Oct', icon: 'transfer', tone: 'blue', self: true },
    { id: 8, m: 'Zomato', sub: 'UPI · HDFC •4821', amt: -640, cat: 'Food', date: '18 Oct', icon: 'food', tone: 'orange' },
  ],
  budgets: [
    { name: 'Food', spent: 11240, limit: 12000, icon: 'food' },
    { name: 'Shopping', spent: 9480, limit: 15000, icon: 'bag' },
    { name: 'Bills', spent: 8420, limit: 9000, icon: 'doc' },
    { name: 'Travel', spent: 4120, limit: 8000, icon: 'car' },
  ],
  alerts: [
    { t: 'Food budget at 94%', s: '₹11,240 of ₹12,000 used', icon: 'bell' },
    { t: 'HDFC card bill due 05 Nov', s: 'Reminder set 5 days before', icon: 'card' },
    { t: '3 possible self transfers', s: 'Please review before month-end', icon: 'transfer' },
  ],
  hidden: [
    { m: 'Office supplies', amt: -3200, date: '15 Oct' },
    { m: 'Client lunch', amt: -1850, date: '12 Oct' },
    { m: 'Courier charges', amt: -420, date: '09 Oct' },
  ],
  selfTransfers: [
    { id: 1, from: 'SBI •1190', to: 'ICICI •7305', amt: 15000, date: '19 Oct', why: 'Same amount debited and credited within 2 minutes' },
    { id: 2, from: 'SBI •1190', to: 'HDFC Credit •4821', amt: 22000, date: '06 Oct', why: 'Payment to your own credit card' },
    { id: 3, from: 'SBI •1190', to: 'Paytm Wallet', amt: 2000, date: '02 Oct', why: 'Transfer to your own wallet' },
  ],
  household: [
    { m: 'D-Mart groceries', who: 'XYZ', amt: -3120, date: '22 Oct' },
    { m: 'Rent', who: 'Sankar', amt: -22000, date: '01 Oct' },
    { m: 'Jio Fiber', who: 'XYZ', amt: -999, date: '05 Oct' },
  ],
};
