import { useEffect, useState } from 'react'
import { listTransactions, bulkCategorize } from '../api/transactions'
import UploadCsv from '../components/UploadCsv'
export default function TransactionsPage(){
  const [rows,setRows]=useState<any[]>([])
  const [sel,setSel]=useState<number[]>([])
  useEffect(()=>{ listTransactions().then(setRows) },[])
  return (
    <div>
      <h1>Transactions</h1>
      <UploadCsv/>
      <table>
        <thead><tr><th></th><th>Date</th><th>Description</th><th>Amount</th><th>Category</th></tr></thead>
        <tbody>
          {rows.map(r=> (
            <tr key={r.id}>
              <td><input type="checkbox" checked={sel.includes(r.id)} onChange={e=> setSel(s=> e.target.checked? [...s,r.id] : s.filter(x=>x!==r.id))}/></td>
              <td>{r.date}</td><td>{r.description}</td><td>{r.amount}</td><td>{r.category_id||'-'}</td>
            </tr>
          ))}
        </tbody>
      </table>
      <div>
        <input id="cat" placeholder="Category" />
        <button onClick={async()=>{
          const name=(document.getElementById('cat') as HTMLInputElement).value
          if(name){ await bulkCategorize(sel,name); alert('Updated'); }
        }}>Bulk Categorize</button>
      </div>
    </div>
  )
}