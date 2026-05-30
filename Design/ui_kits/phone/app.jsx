/* app.jsx — interactive clickthrough for the FitWithFriends Phone UI kit. */

function PhoneApp() {
  const [screen, setScreen] = React.useState("welcome"); // welcome | home | detail
  const [settings, setSettings] = React.useState(false);

  let content;
  if (screen === "welcome") content = <WelcomeScreen onSignIn={()=>setScreen("home")} />;
  else if (screen === "detail") content = <DetailScreen onBack={()=>setScreen("home")} />;
  else content = <HomeScreen onOpenComp={()=>setScreen("detail")} onCreate={()=>{}} onSettings={()=>setSettings(true)} />;

  return <>
    {content}
    {settings && <SettingsSheet onClose={()=>setSettings(false)} onSignOut={()=>{ setSettings(false); setScreen("welcome"); }} />}
  </>;
}

function SettingsSheet({ onClose, onSignOut }) {
  return <div onClick={onClose} style={{ position:"absolute", inset:0, zIndex:80, background:"rgba(0,0,0,0.32)",
    display:"flex", alignItems:"flex-end" }}>
    <div onClick={e=>e.stopPropagation()} style={{ width:"100%", background:"var(--bg)", borderTopLeftRadius:28,
      borderTopRightRadius:28, padding:"12px 16px 40px", maxHeight:"82%", overflow:"auto" }}>
      <div style={{ width:36, height:5, borderRadius:99, background:"var(--ink-faint)", margin:"0 auto 18px" }}/>
      <div style={{ display:"flex", alignItems:"center", gap:14, padding:"4px 4px 18px" }}>
        <Avatar name="Dan Kessler" size={56} />
        <div>
          <div className="fwf-h3" style={{ fontSize:20 }}>Dan Kessler</div>
          <div style={{ fontSize:13, color:"var(--ink-mute)" }}>Member since March 2026</div>
        </div>
      </div>
      <Card padding={0}>
        {[
          { t:"Pro membership", d:"Active", icon:"star", tone:"var(--sun)" },
          { t:"About competitions", icon:"trophy" },
          { t:"Health data", icon:"heart" },
          { t:"Notifications", icon:"refresh" },
        ].map((r,i,a)=>(
          <div key={i} style={{ display:"flex", alignItems:"center", gap:12, padding:"14px 16px",
            borderBottom: i<a.length-1?"0.5px solid var(--border)":"none" }}>
            <Icon name={r.icon} size={18} color={r.tone||"var(--ink-soft)"} />
            <span style={{ flex:1, fontSize:16, color:"var(--ink)" }}>{r.t}</span>
            {r.d && <span style={{ fontSize:14, color:"var(--ink-mute)" }}>{r.d}</span>}
            <Icon name="chevron-right" size={14} color="var(--ink-faint)" />
          </div>))}
      </Card>
      <div style={{ height:18 }}/>
      <Card padding={0}>
        <div onClick={onSignOut} style={{ padding:"14px 16px", fontSize:16, color:"var(--move)", cursor:"pointer", textAlign:"center", fontWeight:500 }}>Sign out</div>
      </Card>
    </div>
  </div>;
}

ReactDOM.createRoot(document.getElementById("root")).render(
  <div style={{ minHeight:"100vh", display:"grid", placeItems:"center", padding:24, background:"#e9e6df" }}>
    <IOSDevice>
      <div style={{ height:"100%", background:"var(--bg)" }}><PhoneApp/></div>
    </IOSDevice>
  </div>
);
