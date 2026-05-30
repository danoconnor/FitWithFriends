/* Screens.jsx — FitWithFriends Phone UI kit screens.
   Depends on Primitives.jsx globals. Recreates WelcomeView, LoggedInContentView,
   TodaySummaryView, CompetitionOverviewView (home card), CompetitionDetailView. */

// ── Sample data ──
const PEOPLE = [
  { name:"Alice Chen",  total:480, today:110, pos:1 },
  { name:"You",         total:422, today:235, pos:2 },
  { name:"Marcus Lee",  total:365, today:125, pos:3 },
  { name:"Priya Nair",  total:288, today:60,  pos:4 },
  { name:"Sam Smith",   total:140, today:0,   pos:5 },
];
const MEDALS = { 1:"var(--gold)", 2:"var(--silver)", 3:"var(--bronze)" };

// ── Wordmark ──
function Wordmark() {
  return <div style={{ display:"flex", alignItems:"center", gap:10 }}>
    <div style={{ width:32, height:32, borderRadius:8, background:"var(--brand)", display:"grid", placeItems:"center" }}>
      <Icon name="flame" size={18} color="#fff" />
    </div>
    <span style={{ fontSize:17, fontWeight:600, color:"var(--ink)" }}>FitWithFriends</span>
  </div>;
}

// ═══ Welcome / sign-in ═══
function WelcomeScreen({ onSignIn }) {
  return <div style={{ minHeight:"100%", background:"var(--bg)", display:"flex", flexDirection:"column",
    padding:"0 22px 32px", boxSizing:"border-box" }}>
    <div style={{ paddingTop:54 }}><Wordmark/></div>
    <div style={{ flex:"0 0 28px" }}/>
    <div style={{ display:"flex", flexDirection:"column", gap:14, marginTop:24 }}>
      <Display prefix={<>Close rings.<br/></>} accent="Beat your friends." size={46} />
      <div style={{ fontSize:16, color:"var(--ink-soft)", lineHeight:1.45, maxWidth:320 }}>
        Weekly fitness competitions with the people in your group chat — powered by Apple Watch.</div>
    </div>

    {/* Leaderboard preview card, tilted -1.5° */}
    <div style={{ marginTop:36, transform:"rotate(-1.5deg)" }}>
      <Card padding={14}>
        <div style={{ display:"flex", alignItems:"center", justifyContent:"space-between", marginBottom:14 }}>
          <Chip tone="brand">Friends Challenge</Chip>
          <span style={{ fontSize:11, fontWeight:600, color:"var(--ink-mute)", fontVariantNumeric:"tabular-nums" }}>4d left</span>
        </div>
        <div style={{ display:"flex", flexDirection:"column", gap:10 }}>
          {PEOPLE.slice(0,3).map((p,i)=>(
            <div key={i} style={{ display:"flex", alignItems:"center", gap:10 }}>
              <Avatar name={p.name} size={26} ring={MEDALS[p.pos]} />
              <div style={{ flex:1 }}>
                <div style={{ fontSize:13, fontWeight:p.name==="You"?700:500, color:"var(--ink)", marginBottom:4 }}>{p.name}</div>
                <div style={{ height:4, borderRadius:99, background:"var(--brand-soft)" }}>
                  <div style={{ height:4, borderRadius:99, background:"var(--brand)", width:`${p.total/480*100}%` }}/></div>
              </div>
              <span style={{ fontSize:13, fontWeight:600, color:"var(--ink)", fontVariantNumeric:"tabular-nums" }}>{p.total}</span>
            </div>))}
        </div>
      </Card>
    </div>

    <div style={{ flex:1 }}/>
    <div style={{ display:"flex", flexDirection:"column", gap:10 }}>
      <PrimaryButton icon="apple" onClick={onSignIn}>Sign in with Apple</PrimaryButton>
      <div style={{ fontSize:12, color:"var(--ink-mute)", textAlign:"center" }}>
        Free to use · Requires Apple Watch or iPhone health data</div>
    </div>
  </div>;
}

// ═══ Home feed ═══
function HomeScreen({ onOpenComp, onCreate, onSettings }) {
  return <div style={{ minHeight:"100%", background:"var(--bg)", paddingTop:48 }}>
    {/* greeting row */}
    <div style={{ display:"flex", alignItems:"center", padding:"8px 20px 4px" }}>
      <div style={{ flex:1 }}>
        <div style={{ fontSize:13, fontWeight:500, color:"var(--ink-mute)" }}>Tuesday · Day 8 of 12</div>
        <div className="fwf-h1">Good evening, Dan</div>
      </div>
      <button onClick={onSettings} style={{ width:40, height:40, borderRadius:"50%", background:"var(--surface)",
        border:"1px solid var(--border)", display:"grid", placeItems:"center", cursor:"pointer" }}>
        <Icon name="settings" size={17} color="var(--ink)" /></button>
    </div>

    <div style={{ display:"flex", flexDirection:"column", gap:16, padding:"12px 16px 28px" }}>
      {/* Today summary */}
      <Card>
        <div style={{ display:"flex", gap:16, alignItems:"flex-start" }}>
          <ActivityRings move={0.72} exercise={1} stand={0.75} size={92} />
          <Display prefix="2 rings closed, " accent="one to go." size={26}
            accentColor="var(--exercise)" style={{ flex:1 }} />
        </div>
        <div style={{ display:"flex", gap:10, marginTop:16, overflowX:"auto" }}>
          {[
            { l:"Move", v:"510", g:"of 700 cal", p:0.72, c:"var(--move)" },
            { l:"Exercise", v:"32", g:"of 30 min", p:1, c:"var(--exercise)" },
            { l:"Stand", v:"9", g:"of 12 hr", p:0.75, c:"var(--stand)" },
            { l:"Steps", v:"8,420", g:"today", p:0, c:"var(--brand)" },
          ].map((s,i)=>(
            <div key={i} style={{ width:110, flex:"none", background:"var(--bg)", borderRadius:12, padding:12 }}>
              <div style={{ fontSize:12, fontWeight:500, color:"var(--ink-mute)" }}>{s.l}</div>
              <div style={{ fontSize:22, fontWeight:700, color:"var(--ink)", fontVariantNumeric:"tabular-nums", marginTop:4 }}>{s.v}</div>
              <div style={{ fontSize:10.5, fontWeight:500, color:"var(--ink-faint)", marginTop:2 }}>{s.g}</div>
              <div style={{ height:3, borderRadius:2, marginTop:8, background:`color-mix(in srgb,${s.c} 15%,transparent)` }}>
                {s.p>0 && <div style={{ height:3, borderRadius:2, background:s.c, width:`${s.p*100}%` }}/>}</div>
            </div>))}
        </div>
      </Card>

      {/* Section: Your Competitions */}
      <div className="fwf-h2" style={{ padding:"4px 4px 0" }}>Your Competitions</div>
      <Card onClick={onOpenComp}><CompetitionHomeCard/></Card>

      {/* Public competition */}
      <div className="fwf-h2" style={{ padding:"4px 4px 0" }}>Public Competitions</div>
      <Card><PublicCompCard/></Card>

      <div style={{ paddingTop:4 }}>
        <SecondaryButton icon="plus" onClick={onCreate}>Start a new competition</SecondaryButton></div>
    </div>
  </div>;
}

function CompetitionHomeCard() {
  return <div style={{ display:"flex", flexDirection:"column", gap:14 }}>
    <div style={{ display:"flex", alignItems:"center", gap:8 }}>
      <Chip tone="mute" icon="lock">Private</Chip>
      <Chip tone="brand" icon="flame">Calorie Burn</Chip>
      <div style={{ flex:1 }}/>
      <div style={{ width:32, height:32, borderRadius:"50%", background:"var(--surface-alt)", display:"grid", placeItems:"center" }}>
        <Icon name="ellipsis" size={14} color="var(--ink-soft)" /></div>
    </div>
    <div className="fwf-title-serif">Saturday Step Showdown</div>
    <div style={{ display:"flex", alignItems:"flex-end", justifyContent:"space-between" }}>
      <div style={{ display:"flex", alignItems:"baseline", gap:4 }}>
        <span style={{ fontSize:40, fontWeight:700, color:"var(--silver)", fontVariantNumeric:"tabular-nums", letterSpacing:"-0.02em" }}>2nd</span>
        <span style={{ fontSize:14, fontWeight:500, color:"var(--ink-mute)" }}>of 5</span>
      </div>
      <div style={{ textAlign:"right" }}>
        <div style={{ fontSize:22, fontWeight:700, color:"var(--exercise)", fontVariantNumeric:"tabular-nums" }}>+235</div>
        <div style={{ fontSize:11, fontWeight:500, color:"var(--ink-mute)" }}>today</div>
      </div>
    </div>
    <div style={{ display:"flex", alignItems:"center", gap:8 }}>
      <Avatar name="Alice Chen" size={22} />
      <span style={{ fontSize:13, color:"var(--ink-soft)" }}><b style={{color:"var(--ink)"}}>Alice Chen</b> is 58 pts ahead</span>
      <div style={{ flex:1 }}/>
      <span style={{ fontSize:11, fontWeight:600, color:"var(--ink-mute)", background:"var(--surface-alt)", padding:"4px 8px", borderRadius:999, fontVariantNumeric:"tabular-nums" }}>4d left</span>
    </div>
  </div>;
}

function PublicCompCard() {
  return <div style={{ display:"flex", flexDirection:"column", gap:12 }}>
    <div style={{ display:"flex", alignItems:"flex-start", justifyContent:"space-between" }}>
      <div style={{ fontSize:22, fontWeight:600, color:"var(--ink)" }}>City Spring 10K Days</div>
      <Chip tone="brand" icon="globe">Public</Chip>
    </div>
    <div style={{ display:"flex", alignItems:"center", justifyContent:"space-between" }}>
      <Chip tone="brand">1,284 members</Chip>
      <span style={{ display:"flex", alignItems:"center", gap:4, fontSize:12, color:"var(--ink-mute)" }}>
        <Icon name="calendar" size={13} color="var(--ink-mute)" />Ends Jun 14</span>
    </div>
    <div style={{ height:1, background:"var(--border)" }}/>
    <PrimaryButton icon="star" >Upgrade to Pro to join</PrimaryButton>
  </div>;
}

// ═══ Competition detail ═══
function DetailScreen({ onBack }) {
  return <div style={{ minHeight:"100%", background:"var(--bg)", position:"relative" }}>
    {/* floating chrome */}
    <div style={{ position:"absolute", top:52, left:16, right:16, display:"flex", justifyContent:"space-between", zIndex:5 }}>
      <ChromeBtn icon="chevron-left" onClick={onBack} />
      <div style={{ display:"flex", gap:10 }}>
        <ChromeBtn icon="share" />
        <ChromeBtn icon="ellipsis" />
      </div>
    </div>

    <div style={{ display:"flex", flexDirection:"column", gap:16, padding:"108px 16px 32px" }}>
      {/* header */}
      <div style={{ padding:"0 4px" }}>
        <Chip tone="mute" icon="lock">Private · 5 friends</Chip>
        <div className="fwf-title-serif" style={{ fontSize:32, marginTop:12 }}>Saturday Step Showdown</div>
        <div style={{ display:"flex", alignItems:"center", gap:8, marginTop:8, fontSize:13, color:"var(--ink-soft)" }}>
          <span>May 23 → Jun 3</span><Dot/><span>Calorie Burn</span><Dot/>
          <span style={{ fontWeight:600, color:"var(--brand)" }}>4 days left</span>
        </div>
      </div>

      {/* standing card */}
      <Card padding={18}>
        <div style={{ display:"flex", justifyContent:"space-between", alignItems:"flex-start" }}>
          <div>
            <div className="fwf-tag">Your standing</div>
            <div style={{ display:"flex", alignItems:"baseline", gap:4, marginTop:4 }}>
              <span style={{ fontSize:36, fontWeight:700, color:"var(--silver)", fontVariantNumeric:"tabular-nums", letterSpacing:"-0.02em" }}>2nd</span>
              <span style={{ fontSize:14, fontWeight:500, color:"var(--ink-mute)" }}>of 5</span>
            </div>
            <div style={{ fontSize:12, color:"var(--ink-soft)", marginTop:4 }}>58 pts behind 1st · 57 pts ahead of 3rd</div>
          </div>
          <div style={{ textAlign:"right" }}>
            <div className="fwf-tag">Time left</div>
            <div style={{ display:"flex", alignItems:"baseline", gap:4, marginTop:4, justifyContent:"flex-end" }}>
              <span style={{ fontSize:32, fontWeight:700, color:"var(--ink)", fontVariantNumeric:"tabular-nums" }}>4</span>
              <span style={{ fontSize:13, fontWeight:500, color:"var(--ink-mute)" }}>days</span>
            </div>
          </div>
        </div>
        <div style={{ marginTop:16 }}>
          <div style={{ height:6, borderRadius:99, background:"var(--brand-soft)" }}>
            <div style={{ height:6, borderRadius:99, width:"67%", background:"linear-gradient(90deg,var(--brand),var(--brand-hi))" }}/></div>
          <div style={{ fontSize:11, fontWeight:500, color:"var(--ink-mute)", marginTop:6 }}>Day 8 of 12 · 67% of the way done</div>
        </div>
      </Card>

      {/* leaderboard */}
      <div style={{ display:"flex", flexDirection:"column", gap:10 }}>
        {PEOPLE.map((p,i)=><LeaderRow key={i} p={p} you={p.name==="You"} />)}
      </div>
    </div>
  </div>;
}

function ChromeBtn({ icon, onClick }) {
  return <button onClick={onClick} style={{ width:38, height:38, borderRadius:"50%", background:"var(--surface)",
    border:"none", display:"grid", placeItems:"center", cursor:"pointer", boxShadow:"var(--shadow-float)" }}>
    <Icon name={icon} size={16} color="var(--ink)" /></button>;
}
function Dot(){ return <span style={{ width:3, height:3, borderRadius:"50%", background:"var(--ink-faint)", display:"inline-block" }}/>; }

function LeaderRow({ p, you }) {
  const medal = MEDALS[p.pos];
  return <div style={{ display:"flex", alignItems:"center", gap:12, padding:"10px 12px", borderRadius:14,
    background: you?"var(--brand-soft)":"var(--surface)",
    border: you?"1.5px solid var(--brand)":"1px solid var(--border)",
    boxShadow: you?"var(--shadow-selected)":"none" }}>
    <div style={{ width:32, height:32, borderRadius:"50%", flex:"none", display:"grid", placeItems:"center",
      background: medal||"transparent", border: medal?"none":"1px solid var(--border)" }}>
      <span style={{ fontSize:14, fontWeight:700, fontVariantNumeric:"tabular-nums", color: medal?"#fff":"var(--ink-soft)" }}>{p.pos}</span></div>
    <Avatar name={p.name} size={32} />
    <div style={{ flex:1 }}>
      <div style={{ fontSize:15, fontWeight:you?700:600, color:"var(--ink)" }}>{p.name}</div>
      {p.today>0 && <div style={{ display:"flex", alignItems:"center", gap:4, marginTop:2 }}>
        <Icon name="arrow-up" size={10} color="var(--exercise)" stroke={3}/>
        <span style={{ fontSize:12, color:"var(--ink-soft)" }}>+{p.today} today</span></div>}
    </div>
    <div style={{ display:"flex", alignItems:"baseline", gap:2 }}>
      <span style={{ fontSize:20, fontWeight:700, color:"var(--ink)", fontVariantNumeric:"tabular-nums" }}>{p.total}</span>
      <span style={{ fontSize:11, fontWeight:500, color:"var(--ink-mute)" }}>pts</span></div>
  </div>;
}

Object.assign(window, { WelcomeScreen, HomeScreen, DetailScreen, PEOPLE, MEDALS });
