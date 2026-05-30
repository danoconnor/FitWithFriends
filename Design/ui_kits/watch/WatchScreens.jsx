/* WatchScreens.jsx — Apple Watch app screens.
   Now aligned to the SHARED editorial design system (dark-mode tokens from
   colors_and_type.css): indigo Brand, serif competition names, green "+today"
   deltas, paper-dark surfaces. The root is wrapped in [data-theme="dark"]. */

const MEDAL_W = { 1:"var(--gold)", 2:"var(--silver)", 3:"var(--bronze)" };

const WATCH_COMPS = [
  { name:"Saturday Step Showdown", active:true,
    rows:[
      { name:"Alice Chen", pts:480, today:110, pos:1 },
      { name:"You",        pts:422, today:235, pos:2, me:true },
      { name:"Marcus Lee", pts:365, today:125, pos:3 },
      { name:"Priya Nair", pts:288, today:60,  pos:4 },
    ], myPos:2, myPts:422, myToday:235, count:5 },
  { name:"Office May Movement", active:true,
    rows:[
      { name:"You",       pts:612, today:90, pos:1, me:true },
      { name:"Jordan W.", pts:540, today:40, pos:2 },
      { name:"Lena R.",   pts:498, today:120, pos:3 },
    ], myPos:1, myPts:612, myToday:90, count:12 },
];

const ordinal = n => { const s=["th","st","nd","rd"], v=n%100; return n+(s[(v-20)%10]||s[v]||s[0]); };

// Top status strip (time, native watchOS look — brand-tinted title)
function WatchStatus({ title }) {
  return <div style={{ position:"sticky", top:0, zIndex:5,
    background:"linear-gradient(var(--bg),var(--bg) 70%,transparent)",
    padding:"7px 16px 4px", display:"flex", alignItems:"center", justifyContent:"space-between" }}>
    <span style={{ fontSize:13, fontWeight:600, color:"var(--brand)" }}>{title}</span>
    <span style={{ fontSize:13, fontWeight:600, color:"var(--ink)", fontVariantNumeric:"tabular-nums" }}>9:41</span>
  </div>;
}

// ═══ Signed out ═══
function WatchSignedOut() {
  return <div style={{ height:"100%", background:"var(--bg)", color:"var(--ink)", display:"flex", flexDirection:"column",
    alignItems:"center", justifyContent:"center", gap:10, padding:"0 22px", textAlign:"center" }}>
    <div style={{ width:46, height:46, borderRadius:12, background:"var(--brand)", display:"grid", placeItems:"center" }}>
      <WIcon name="flame" size={24} color="#fff" /></div>
    <div style={{ fontSize:15, fontWeight:600 }}>Sign in on iPhone</div>
    <div style={{ fontSize:12, color:"var(--ink-mute)", lineHeight:1.35 }}>Open FitWithFriends on your iPhone to get started.</div>
  </div>;
}

// ═══ Competitions pager ═══
function WatchPager({ onOpen }) {
  const [page, setPage] = React.useState(0);
  return <div style={{ height:"100%", background:"var(--bg)", color:"var(--ink)", overflow:"auto", position:"relative" }}>
    <WatchStatus title="Competitions" />
    <div style={{ padding:"0 10px 14px" }}>
      <WatchCompCard comp={WATCH_COMPS[page]} onOpen={onOpen} />
    </div>
    {/* page dots */}
    <div style={{ position:"sticky", bottom:8, display:"flex", justifyContent:"center", gap:6 }}>
      {WATCH_COMPS.map((_,i)=>(
        <div key={i} onClick={()=>setPage(i)} style={{ width:6, height:6, borderRadius:"50%", cursor:"pointer",
          background: i===page ? "var(--ink)" : "var(--ink-faint)" }}/>))}
    </div>
  </div>;
}

function WatchCompCard({ comp, onOpen }) {
  const top3 = comp.rows.slice(0,3);
  return <div style={{ display:"flex", flexDirection:"column", gap:8 }}>
    {/* competition name — serif, matching the phone app */}
    <div style={{ fontFamily:"var(--font-serif)", fontSize:18, fontWeight:400, lineHeight:1.1,
      letterSpacing:"-0.02em", color:"var(--ink)" }}>{comp.name}</div>

    {/* hero block — brand-soft tint */}
    <div style={{ borderRadius:14, background:"var(--brand-soft)", padding:"8px 6px", textAlign:"center" }}>
      <div style={{ fontFamily:"var(--font-rounded)", fontSize:24, fontWeight:700, fontVariantNumeric:"tabular-nums",
        color: MEDAL_W[comp.myPos] || "var(--ink)" }}>{ordinal(comp.myPos)}</div>
      <div style={{ fontSize:12, color:"var(--ink-mute)", fontVariantNumeric:"tabular-nums" }}>{comp.myPts} points</div>
      {comp.active && comp.myToday>0 && <div style={{ fontSize:11, color:"var(--exercise)", fontVariantNumeric:"tabular-nums" }}>+{comp.myToday} today</div>}
    </div>

    <div style={{ height:0.5, background:"var(--border-strong)" }}/>

    {/* top 3 */}
    <div style={{ display:"flex", flexDirection:"column", gap:4 }}>
      {top3.map((r,i)=><WatchRow key={i} r={r} active={comp.active} onClick={()=>onOpen(r)} />)}
    </div>

    <div style={{ fontSize:11, color:"var(--ink-mute)", textAlign:"center", marginTop:4 }}>
      You're {ordinal(comp.myPos)} of {comp.count}</div>
  </div>;
}

function WatchRow({ r, active, onClick }) {
  const medal = MEDAL_W[r.pos];
  return <div onClick={onClick} style={{ display:"flex", alignItems:"center", gap:8, cursor:"pointer",
    background: r.me ? "var(--brand-soft)" : "transparent", borderRadius:10, padding: r.me ? "3px 6px" : "3px 0",
    margin: r.me ? "0 -6px" : 0 }}>
    <div style={{ width:22, height:22, borderRadius:"50%", flex:"none", display:"grid", placeItems:"center",
      background: medal||"transparent", border: medal?"none":"1px solid var(--border-strong)" }}>
      <span style={{ fontSize:10, fontWeight:700, color: medal?"#fff":"var(--ink-mute)" }}>{r.pos}</span></div>
    <div style={{ flex:1, minWidth:0 }}>
      <div style={{ fontSize:12, fontWeight:r.me?700:500, color:"var(--ink)", whiteSpace:"nowrap", overflow:"hidden", textOverflow:"ellipsis" }}>{r.name}</div>
      {active && r.today>0 && <div style={{ fontSize:9, color:"var(--ink-mute)" }}>+{r.today} today</div>}
    </div>
    <span style={{ fontSize:13, fontWeight:600, color:"var(--ink)", fontVariantNumeric:"tabular-nums" }}>{r.pts}</span>
  </div>;
}

// ═══ Daily details (carousel list) ═══
const DAILY = [
  { d:"Jun 2", pts:235, cal:"510/700", min:"32/30", h:"9/12" },
  { d:"Jun 1", pts:188, cal:"640/700", min:"24/30", h:"11/12" },
  { d:"May 31", pts:142, cal:"410/700", min:"18/30", h:"8/12" },
  { d:"May 30", pts:266, cal:"700/700", min:"41/30", h:"12/12" },
];
function WatchDailyDetails({ person, onBack }) {
  const total = DAILY.reduce((a,b)=>a+b.pts,0);
  return <div style={{ height:"100%", background:"var(--bg)", color:"var(--ink)", overflow:"auto" }}>
    <div style={{ position:"sticky", top:0, zIndex:5,
      background:"linear-gradient(var(--bg),var(--bg) 70%,transparent)",
      padding:"7px 12px 4px", display:"flex", alignItems:"center", gap:6 }}>
      <div onClick={onBack} style={{ cursor:"pointer", display:"flex", alignItems:"center" }}>
        <WIcon name="chevron-left" size={14} color="var(--brand)" /></div>
      <span style={{ fontSize:13, fontWeight:600, flex:1, textAlign:"center", color:"var(--ink)" }}>{person?.name || "You"}</span>
      <span style={{ fontSize:13, fontWeight:600, fontVariantNumeric:"tabular-nums", color:"var(--ink)" }}>9:41</span>
    </div>
    <div style={{ textAlign:"center", padding:"4px 0 8px" }}>
      <div style={{ fontFamily:"var(--font-rounded)", fontSize:20, fontWeight:700, fontVariantNumeric:"tabular-nums", color:"var(--ink)" }}>{total} pts</div>
      <div style={{ fontSize:11, color:"var(--ink-mute)" }}>Total points</div>
    </div>
    <div style={{ display:"flex", flexDirection:"column", gap:6, padding:"0 10px 16px" }}>
      {DAILY.map((s,i)=>(
        <div key={i} style={{ background:"var(--surface)", borderRadius:14, padding:"8px 10px",
          border:"1px solid var(--border)" }}>
          <div style={{ display:"flex", justifyContent:"space-between" }}>
            <span style={{ fontSize:12, fontWeight:600, color:"var(--ink)" }}>{s.d}</span>
            <span style={{ fontSize:12, fontWeight:600, fontVariantNumeric:"tabular-nums", color:"var(--ink)" }}>{s.pts}</span></div>
          <div style={{ fontSize:9, color:"var(--ink-mute)", marginTop:2 }}>{s.cal} Cal · {s.min} Min · {s.h} h</div>
        </div>))}
    </div>
  </div>;
}

// tiny icon helper for the watch (subset)
function WIcon({ name, size=16, color="#fff" }) {
  if (name==="chevron-left") return <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke={color} strokeWidth="2.4" strokeLinecap="round" strokeLinejoin="round"><path d="M15 6l-6 6 6 6"/></svg>;
  if (name==="flame") return <svg width={size} height={size} viewBox="0 0 24 24"><path fill={color} d="M12 3c1 3-1.5 4-1.5 6.5A2.5 2.5 0 0 0 13 12c0-1 .8-1.7.8-1.7.7 1 1.7 2.2 1.7 4.2a4.5 4.5 0 1 1-9 0C6.5 10 12 8 12 3z"/></svg>;
  return null;
}

Object.assign(window, { WatchSignedOut, WatchPager, WatchDailyDetails, WIcon });
