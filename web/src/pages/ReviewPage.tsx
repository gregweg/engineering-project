import { useEffect, useState } from 'react'
import { review, bulkCategorize } from '../api/transactions'
export default function ReviewPage(){
  const [uncat,setUncat]=useState<any[]>([])
  const [flagged,setFlagged]=useState<any[]>([])
  useEffect(()=>{ review().then(d=>{ setUncat(d.uncategorized); setFlagged(d.flagged); }) },[])
  return (
    <div>
      <h2>Needs Category</h2>
      {uncat.map(u=> (<div key={u.id}>{u.date} {u.description} ${u.amount}</div>))}
      <h2>Flagged</h2>
      {flagged.map(f=> (<div key={f.id}>{f.date} {f.description} ${f.amount} (flag)</div>))}
    </div>
  )
}