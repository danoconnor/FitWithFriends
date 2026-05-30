/* Primitives.jsx — FitWithFriends Phone UI kit
   Mirrors FWFStyles.swift. Colors come from ../../colors_and_type.css vars.
   Icons: SF Symbols on device → curated Lucide-style stroke set on web. */

// ── Icon set (SF Symbol → nearest Lucide-style glyph, drawn inline for reliability) ──
// We render the small curated set with explicit SVG so sizing/color follow props.
function Icon({ name, size = 18, color = "currentColor", stroke = 2, style = {} }) {
  const common = { width: size, height: size, viewBox: "0 0 24 24", fill: "none",
    stroke: color, strokeWidth: stroke, strokeLinecap: "round", strokeLinejoin: "round",
    style: { display: "block", ...style } };
  switch (name) {
    case "apple": return (
      <svg width={size} height={size} viewBox="0 0 24 24" style={{display:"block",...style}}>
        <path fill={color} d="M17.05 12.04c-.03-2.6 2.12-3.85 2.22-3.91-1.21-1.77-3.09-2.01-3.76-2.04-1.6-.16-3.12.94-3.93.94-.81 0-2.06-.92-3.39-.89-1.74.03-3.35 1.01-4.25 2.57-1.81 3.14-.46 7.79 1.3 10.34.86 1.25 1.89 2.65 3.23 2.6 1.3-.05 1.79-.84 3.36-.84 1.57 0 2.01.84 3.39.81 1.4-.02 2.29-1.27 3.15-2.53.99-1.45 1.4-2.85 1.42-2.92-.03-.01-2.73-1.05-2.76-4.15"/>
        <path fill={color} d="M14.46 4.5c.71-.86 1.19-2.06 1.06-3.25-1.02.04-2.26.68-3 1.54-.66.76-1.24 1.98-1.08 3.15 1.14.09 2.3-.58 3.02-1.44"/>
      </svg>
    );
    case "plus": return <svg {...common}><path d="M12 5v14M5 12h14"/></svg>;
    case "globe": return <svg {...common}><circle cx="12" cy="12" r="9"/><path d="M3 12h18M12 3a14 14 0 0 1 0 18 14 14 0 0 1 0-18"/></svg>;
    case "lock": return <svg width={size} height={size} viewBox="0 0 24 24" style={{display:"block",...style}}><rect x="5" y="11" width="14" height="9" rx="2" fill={color}/><path d="M8 11V8a4 4 0 0 1 8 0v3" fill="none" stroke={color} strokeWidth={stroke}/></svg>;
    case "settings": return <svg width={size} height={size} viewBox="0 0 24 24" style={{display:"block",...style}}><path fill="none" stroke={color} strokeWidth={stroke} strokeLinejoin="round" d="M19.4 13a7.8 7.8 0 0 0 0-2l1.9-1.5-2-3.4-2.2 1a7.4 7.4 0 0 0-1.8-1l-.3-2.4h-4l-.3 2.4a7.4 7.4 0 0 0-1.8 1l-2.2-1-2 3.4L4.6 11a7.8 7.8 0 0 0 0 2l-1.9 1.5 2 3.4 2.2-1a7.4 7.4 0 0 0 1.8 1l.3 2.4h4l.3-2.4a7.4 7.4 0 0 0 1.8-1l2.2 1 2-3.4z"/><circle cx="12" cy="12" r="2.6" fill="none" stroke={color} strokeWidth={stroke}/></svg>;
    case "ellipsis": return <svg width={size} height={size} viewBox="0 0 24 24" style={{display:"block",...style}}><circle cx="5" cy="12" r="1.8" fill={color}/><circle cx="12" cy="12" r="1.8" fill={color}/><circle cx="19" cy="12" r="1.8" fill={color}/></svg>;
    case "chevron-left": return <svg {...common}><path d="M15 6l-6 6 6 6"/></svg>;
    case "chevron-right": return <svg {...common}><path d="M9 6l6 6-6 6"/></svg>;
    case "share": return <svg {...common}><path d="M12 15V4M8.5 7.5L12 4l3.5 3.5"/><path d="M6 12v6a2 2 0 0 0 2 2h8a2 2 0 0 0 2-2v-6"/></svg>;
    case "calendar": return <svg {...common}><rect x="4" y="5" width="16" height="16" rx="2"/><path d="M8 3v4M16 3v4M4 10h16"/></svg>;
    case "trophy": return <svg width={size} height={size} viewBox="0 0 24 24" style={{display:"block",...style}}><path fill={color} d="M7 4h10v3a5 5 0 0 1-10 0V4z"/><path fill="none" stroke={color} strokeWidth={stroke} strokeLinecap="round" d="M7 5H4v2a3 3 0 0 0 3 3M17 5h3v2a3 3 0 0 1-3 3M12 12v3M8.5 20h7M9.5 20c0-1.5 1-2.5 2.5-2.5s2.5 1 2.5 2.5"/></svg>;
    case "star": return <svg width={size} height={size} viewBox="0 0 24 24" style={{display:"block",...style}}><path fill={color} d="M12 3l2.6 5.6 6 .8-4.4 4.2 1.1 6L12 17.8 6.7 19.6l1.1-6L3.4 9.4l6-.8z"/></svg>;
    case "arrow-up": return <svg {...common}><path d="M12 19V6M6 11l6-6 6 6"/></svg>;
    case "check-circle": return <svg width={size} height={size} viewBox="0 0 24 24" style={{display:"block",...style}}><circle cx="12" cy="12" r="9" fill={color}/><path d="M8.5 12.5l2.5 2.5 4.5-5" fill="none" stroke="#fff" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/></svg>;
    case "flame": return <svg width={size} height={size} viewBox="0 0 24 24" style={{display:"block",...style}}><path fill={color} d="M12 3c1 3-1.5 4-1.5 6.5A2.5 2.5 0 0 0 13 12c0-1 .8-1.7.8-1.7.7 1 1.7 2.2 1.7 4.2a4.5 4.5 0 1 1-9 0C6.5 10 12 8 12 3z"/></svg>;
    case "footprints": return <svg width={size} height={size} viewBox="0 0 24 24" style={{display:"block",...style}}><path fill={color} d="M6 4c1.5 0 2.5 1.6 2.5 4S7.5 16 6 16s-2.5-2-2.5-4S4.5 4 6 4zM4 17h4v2a2 2 0 0 1-4 0v-2zM17 7c1.5 0 2.5 1.6 2.5 4S18.5 19 17 19s-2.5-2-2.5-4S15.5 7 17 7zM15 20h4v-1a2 2 0 0 0-4 0v1z"/></svg>;
    case "refresh": return <svg {...common}><path d="M3 12a9 9 0 0 1 15-6.7L21 8M21 3v5h-5"/></svg>;
    case "heart": return <svg width={size} height={size} viewBox="0 0 24 24" style={{display:"block",...style}}><path fill={color} d="M12 20s-7-4.3-7-9.3A3.7 3.7 0 0 1 12 8a3.7 3.7 0 0 1 7 2.7c0 5-7 9.3-7 9.3z"/></svg>;
    default: return <svg {...common}><circle cx="12" cy="12" r="9"/></svg>;
  }
}

// ── Deterministic avatar ──
const AVATAR_PALETTE = ["#fa114f","#3c5bbf","#92e82a","#f2a03e","#1eeaef","#d9a33a","#7a5bc0","#2a8c66"];
function avatarColor(name){ let h=0; for(const c of name) h+=c.charCodeAt(0); return AVATAR_PALETTE[h%AVATAR_PALETTE.length]; }
function initials(name){ return name.split(" ").slice(0,2).map(p=>p[0]||"").join("").toUpperCase(); }

function Avatar({ name, size = 36, ring }) {
  return (
    <div style={{ position:"relative", width:size, height:size, flex:"none" }}>
      <div style={{ width:size, height:size, borderRadius:"50%", background:avatarColor(name),
        color:"#fff", fontWeight:600, fontSize:size*0.36, display:"grid", placeItems:"center",
        border: ring ? "1.5px solid #fff" : "none", boxSizing:"border-box" }}>{initials(name)}</div>
      {ring && <div style={{ position:"absolute", inset:-3.5, borderRadius:"50%", border:`2.5px solid ${ring}` }} />}
    </div>
  );
}

// ── Card ──
function Card({ children, style = {}, padding = 16, onClick }) {
  return <div onClick={onClick} style={{ background:"var(--surface)", borderRadius:22, padding,
    boxShadow:"var(--shadow-card)", cursor:onClick?"pointer":"default", ...style }}>{children}</div>;
}

// ── Chip ──
function Chip({ children, icon, tone = "mute" }) {
  const map = {
    mute:   { bg:"var(--surface-alt)", fg:"var(--ink-mute)" },
    brand:  { bg:"var(--brand-soft)",  fg:"var(--brand)" },
    move:   { bg:"var(--move-soft)",   fg:"var(--move)" },
    sun:    { bg:"color-mix(in srgb,var(--sun) 14%,transparent)", fg:"var(--sun)" },
  };
  const c = map[tone] || map.mute;
  return <span style={{ display:"inline-flex", alignItems:"center", gap:4, background:c.bg, color:c.fg,
    fontWeight:600, fontSize:10.5, letterSpacing:"0.06em", textTransform:"uppercase",
    padding:"4px 8px", borderRadius:999 }}>
    {icon && <Icon name={icon} size={11} color={c.fg} stroke={2.4} />}{children}</span>;
}

// ── Buttons ──
function PrimaryButton({ children, icon, onClick }) {
  return <button onClick={onClick} style={{ display:"flex", alignItems:"center", justifyContent:"center", gap:8,
    height:54, width:"100%", border:"none", borderRadius:16, background:"var(--ink)", color:"var(--bg-deep)",
    fontFamily:"var(--font-sans)", fontWeight:600, fontSize:16, cursor:"pointer" }}>
    {icon && <Icon name={icon} size={17} color="var(--bg-deep)" stroke={2.2} />}{children}</button>;
}
function SecondaryButton({ children, icon, onClick }) {
  return <button onClick={onClick} style={{ display:"flex", alignItems:"center", justifyContent:"center", gap:8,
    height:56, width:"100%", borderRadius:18, background:"transparent", color:"var(--brand)",
    border:"1.5px dashed color-mix(in srgb,var(--brand) 70%,transparent)",
    fontFamily:"var(--font-sans)", fontWeight:600, fontSize:16, cursor:"pointer" }}>
    {icon && <Icon name={icon} size={17} color="var(--brand)" stroke={2.2} />}{children}</button>;
}

// ── Display headline (serif, italic accent) ──
function Display({ prefix, accent, size = 48, accentColor = "var(--brand)", style = {} }) {
  return <div style={{ fontFamily:"var(--font-serif)", fontWeight:400, fontSize:size, lineHeight:1.02,
    letterSpacing:"-0.02em", color:"var(--ink)", ...style }}>
    {prefix}{accent && <span style={{ fontStyle:"italic", color:accentColor }}>{accent}</span>}</div>;
}

// ── Activity rings (three concentric arcs: Move / Exercise / Stand) ──
function ActivityRings({ move = 0.72, exercise = 1, stand = 0.75, size = 92 }) {
  const ring = (r, frac, color, w) => {
    const C = 2 * Math.PI * r;
    return <>
      <circle cx={size/2} cy={size/2} r={r} fill="none" stroke={color} strokeOpacity={0.18} strokeWidth={w} />
      <circle cx={size/2} cy={size/2} r={r} fill="none" stroke={color} strokeWidth={w} strokeLinecap="round"
        strokeDasharray={`${C*Math.min(frac,1)} ${C}`} transform={`rotate(-90 ${size/2} ${size/2})`} />
    </>;
  };
  const w = size*0.11;
  return <svg width={size} height={size} viewBox={`0 0 ${size} ${size}`} style={{flex:"none"}}>
    {ring(size/2 - w/2 - 1, move, "var(--move)", w)}
    {ring(size/2 - w*1.5 - 3, exercise, "var(--exercise)", w)}
    {ring(size/2 - w*2.5 - 5, stand, "var(--stand)", w)}
  </svg>;
}

Object.assign(window, { Icon, Avatar, avatarColor, initials, Card, Chip, PrimaryButton, SecondaryButton, Display, ActivityRings });
