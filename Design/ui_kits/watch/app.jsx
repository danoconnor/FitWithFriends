/* app.jsx — Apple Watch UI kit clickthrough. */

function WatchApp() {
  const [view, setView] = React.useState("pager"); // pager | details | signedout
  const [person, setPerson] = React.useState(null);

  let screen;
  if (view === "signedout") screen = <WatchSignedOut/>;
  else if (view === "details") screen = <WatchDailyDetails person={person} onBack={()=>setView("pager")} />;
  else screen = <WatchPager onOpen={(p)=>{ setPerson(p); setView("details"); }} />;

  return <WatchFrame scale={1.7}>{screen}</WatchFrame>;
}

ReactDOM.createRoot(document.getElementById("root")).render(
  <div data-theme="dark" style={{ minHeight:"100vh", display:"grid", placeItems:"center", padding:40, background:"#e9e6df" }}>
    <WatchApp/>
  </div>
);
