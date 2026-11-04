# Demo F1 — ciclo de vida completo de un pedido contra servicio-ventas (M1).
# Uso (PowerShell):  .\demo-f1.ps1                          (usa Render)
#                    .\demo-f1.ps1 -Api http://localhost:8081  (backend local)
# Requisitos: M1 con SEGURIDAD_HABILITADA=false o, si la seguridad está activa, pasar -Token con un
# token que tenga los scopes/roles de cada paso (ver api-ventas.md, catálogo de scopes).
# Crea datos reales en la base a la que apunte: usar solo para la demo.
param(
    [string]$Api = "https://g5-servicio-ventas.onrender.com",
    [string]$Token = ""
)
$ErrorActionPreference = "Stop"

function Llamar($metodo, $ruta, $cuerpo, $idempotencia) {
    $h = @{ "Content-Type" = "application/json" }
    if ($Token) { $h["Authorization"] = "Bearer $Token" }
    if ($idempotencia) { $h["Idempotency-Key"] = $idempotencia }
    $json = if ($cuerpo) { $cuerpo | ConvertTo-Json -Depth 6 } else { $null }
    try {
        return Invoke-RestMethod -Method $metodo -Uri "$Api$ruta" -Headers $h -Body $json -TimeoutSec 120
    } catch {
        $r = $_.Exception.Response
        if ($r) {
            $texto = (New-Object IO.StreamReader($r.GetResponseStream())).ReadToEnd()
            Write-Host "  -> HTTP $([int]$r.StatusCode): $texto" -ForegroundColor Yellow
            return $null
        }
        throw
    }
}
function Paso($titulo) { Write-Host "`n=== $titulo ===" -ForegroundColor Cyan; Read-Host "  [Enter para ejecutar]" | Out-Null }
function Estado($pedidoId) { (Llamar GET "/api/v1/pedidos/$pedidoId").estado }

Paso "1.1 Crear pedido (canal CHATBOT) -> CREADO"
$clave = [guid]::NewGuid().ToString()
$pedido = @{
    canal    = "CHATBOT"
    contacto = @{ clienteId = "11111111-1111-1111-1111-111111111111"; nombreCompleto = "Cliente Demo Hito 4"
                  tipoDocumento = "DNI"; numeroDocumento = "72458912"; telefono = "+51999888777"; email = "demo@example.com" }
    items    = @(@{ productoId = "PROD-101"; sku = "SKU-AUR-01"; descripcion = "Audífonos Bluetooth"; cantidad = 1; precioUnitario = 129.90 })
    envio    = @{ modalidad = "DELIVERY"; costo = 10.00; destinatario = "Cliente Demo"; departamento = "Lima"; provincia = "Lima"
                  distrito = "San Miguel"; direccion = "Av. La Marina 1234"; referencia = "Frente al centro comercial" }
    pago     = @{ metodoPago = "TARJETA_CREDITO"; moneda = "PEN"; subtotal = 129.90; descuentoCupon = 0; costoEnvio = 10.00; total = 139.90 }
}
$creado = Llamar POST "/api/v1/pedidos" $pedido $clave
if (-not $creado) { Write-Host "No se pudo crear el pedido; revisa el error de arriba." -ForegroundColor Red; exit 1 }
$id = $creado.pedidoId
Write-Host "  Pedido $id en estado $($creado.estado)"

Paso "Idempotencia: reenviar el mismo pedido con la misma Idempotency-Key (no crea otro)"
$repetido = Llamar POST "/api/v1/pedidos" $pedido $clave
Write-Host "  Devuelve el mismo pedido: $($repetido.pedidoId)"

Paso "1.2 Notificación de pago APROBADO -> PAGADO"
$pago = @{ transaccionId = "TX-DEMO-$([guid]::NewGuid().ToString().Substring(0,8))"; resultado = "APROBADO"; monto = 139.90
           moneda = "PEN"; metodo = "TARJETA_CREDITO"; fechaPago = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ") }
$r = Llamar POST "/api/v1/pedidos/$id/pagos/notificacion" $pago
Write-Host "  Nuevo estado: $($r.nuevoEstado)"

Paso "1.12 Gestor: Iniciar preparación -> EN_PREPARACION (también se puede hacer desde el detalle del pedido en Vercel)"
$r = Llamar POST "/api/v1/pedidos/$id/preparacion"
Write-Host "  $($r.mensaje) — estado $($r.estado)"

Paso "1.13 Gestor: Paquete sellado (crea el despacho; con Despacho simulado no llama a G2)"
$r = Llamar POST "/api/v1/pedidos/$id/despacho"
if ($r) { Write-Host "  $($r.mensaje) — idDespacho $($r.idDespacho)" }

Paso "1.5 Despacho avisa DESPACHO_EN_CAMINO -> DESPACHADO"
$evento = @{ idEvento = "evt-demo-$([guid]::NewGuid().ToString().Substring(0,8))"; idPedido = $id; idDespacho = "DESP-DEMO"
             tipo = "DESPACHO_EN_CAMINO"; ocurridoEn = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ"); datos = @{} }
$r = Llamar POST "/api/v1/integraciones/despachos/eventos" $evento ([guid]::NewGuid().ToString())
Write-Host "  $($r.mensaje)"

Paso "Máquina de estados: intentar 'Iniciar preparación' sobre un pedido DESPACHADO (debe dar 409 TRANSICION_NO_PERMITIDA)"
Llamar POST "/api/v1/pedidos/$id/preparacion" | Out-Null

Paso "1.5 Despacho avisa DESPACHO_ENTREGADO -> ENTREGADO"
$evento.idEvento = "evt-demo-$([guid]::NewGuid().ToString().Substring(0,8))"
$evento.tipo = "DESPACHO_ENTREGADO"
$r = Llamar POST "/api/v1/integraciones/despachos/eventos" $evento ([guid]::NewGuid().ToString())
Write-Host "  $($r.mensaje)"

Paso "1.3 Consultar el pedido: estado final e historial completo"
$detalle = Llamar GET "/api/v1/pedidos/$id"
Write-Host "  Estado final: $($detalle.estado)"
$detalle.historialEstados | Format-Table estado, actor, fecha, motivo -AutoSize
Write-Host "Listo. Busca $id en la bandeja de pedidos del frontend para mostrar el detalle y el historial." -ForegroundColor Green
