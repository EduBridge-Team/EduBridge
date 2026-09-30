export default function FormField({ label, children }) {
  return <label className="form-field"><span>{label}</span>{children}</label>
}
