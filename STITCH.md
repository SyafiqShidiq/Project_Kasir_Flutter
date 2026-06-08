# Stitch MCP Connection

This Flutter workspace is connected to the following Google Stitch project through the available Stitch MCP tools.

- Project URL: https://stitch.withgoogle.com/projects/7784457451065927667
- Project resource: `projects/7784457451065927667`
- Title: `Remix of SmartCashier Mobile POS System`
- Device target: `MOBILE`
- Visibility: `PRIVATE`
- Design system: `SmartCashier Design System`
- Design system asset: `assets/ac02d608dd154e6aa9cdb4a6d3877ee7`

## Flutter Theme Mapping

Use these values when implementing the Flutter app theme:

- Material: Material Design 3
- Font family: `Inter`
- Primary red: `#D32F2F`
- Primary: `#AF101A`
- Background: `#F9F9F9`
- Surface: `#F9F9F9`
- Surface container: `#EEEEEE`
- Surface variant: `#E2E2E2`
- Text on surface: `#1A1C1C`
- Outline: `#8F6F6C`
- Error: `#BA1A1A`
- Mobile margin: `16px`
- Gutter: `12px`
- Base spacing unit: `8px`

## Stitch Screens

| Screen | Resource |
| --- | --- |
| Login - SmartCashier | `projects/7784457451065927667/screens/02e64b77814c42ceb184e0eaf34f3bdb` |
| Home - Customer | `projects/7784457451065927667/screens/5032efd71c624a4680c1960e58382fdb` |
| Checkout - SmartCashier | `projects/7784457451065927667/screens/70428714278f462aaf10670664303847` |
| Order Detail - Cashier | `projects/7784457451065927667/screens/0239eb1923a845b6b2177c21b98dd019` |
| Dashboard - Cashier | `projects/7784457451065927667/screens/c5102534f2f14bfeb07de580cf792b26` |
| QR Payment - SmartCashier | `projects/7784457451065927667/screens/d24d8ca772a64c6abb55ba5f2ad0a007` |
| Order Tracking - SmartCashier | `projects/7784457451065927667/screens/b9b16000865f4565a385d76dfec92e0f` |
| Cart - SmartCashier | `projects/7784457451065927667/screens/c05a94775e1d4c21940531307873ab7d` |
| QuickServe Food Service Flow | `projects/7784457451065927667/screens/c16280ab9e3c4ac5ae8e4925392e8e56` |
| SmartCashier Logo | `projects/7784457451065927667/screens/ab4dda779547440c8891e091b1bc83ca` |

## MCP Usage

Useful Stitch MCP calls for this project:

```text
get_project(name: "projects/7784457451065927667")
list_screens(projectId: "7784457451065927667")
list_design_systems(projectId: "7784457451065927667")
get_screen(
  name: "projects/7784457451065927667/screens/<screen-id>",
  projectId: "7784457451065927667",
  screenId: "<screen-id>"
)
```
