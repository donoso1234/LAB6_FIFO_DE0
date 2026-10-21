# Laboratorio No. 6 — FIFO Buffer en FPGA Terasic DE0

**Pontificia Universidad Javeriana — Ingeniería Electrónica — Diseño de Sistemas Digitales**  
**Implementación:** FIFO síncrona circular en VHDL, simulación en ModelSim y verificación en la Terasic DE0 original (Cyclone III).

## Descripción

Este repositorio contiene los **códigos fuente VHDL** y los **testbenches** del Laboratorio No. 6. Se completó un controlador de FIFO circular para ocho posiciones y después se parametrizó una versión de **16 posiciones × 4 bits** (64 bits de almacenamiento) para montarla en una FPGA Terasic DE0.

La FIFO respeta el principio *First In, First Out*: el primer dato que entra es el primero que sale. El controlador administra los apuntadores `w_ptr` (escritura) y `r_ptr` (lectura), así como las banderas `full` y `empty`.

## Arquitectura y funcionamiento

- `register_file.vhd`: escritura síncrona en el flanco ascendente del reloj y lectura combinacional desde la dirección `r_addr`.
- `fifo_ctrl.vhd`: incrementa circularmente los apuntadores y genera `full` y `empty`.
- `fifo.vhd`: conecta el controlador a la memoria, bloquea las escrituras en estado lleno y entrega cero en `r_data` cuando la FIFO está vacía.
- `button_onepulse.vhd`: sincroniza los pulsadores activos en bajo y genera un pulso por pulsación con filtro de aproximadamente 10 ms a 50 MHz.
- `hex7seg.vhd`: visualiza los valores 0–F en displays activos en bajo.
- `de0_fifo_top.vhd`: integra la FIFO de 16 × 4 con los elementos físicos de la tarjeta.

El controlador permite lectura y escritura simultáneas cuando la FIFO no está vacía ni llena. Cuando está vacía, solo se admite escritura; cuando está llena, solo se admite lectura. Esta decisión corresponde a la implementación entregada.

## Cómo simular en ModelSim — sin archivos .do

Abre ModelSim, selecciona **File → Change Directory** y ubícate en la carpeta donde guardaste los archivos `.vhd`. Después, escribe estos comandos en **Transcript**:

```tcl
vlib work
vcom register_file.vhd
vcom fifo_ctrl.vhd
vcom fifo.vhd
vcom tb_fifo8.vhd
vcom tb_fifo16.vhd
vsim work.tb_fifo8
add wave *
run 1000 ns
WaveRestoreZoom {0 ns} {300 ns}
```

Para ejecutar el testbench de 16 posiciones:

```tcl
quit -sim
vsim work.tb_fifo16
add wave *
run 1000 ns
WaveRestoreZoom {0 ns} {380 ns}
```

Si la biblioteca `work` ya existe, omite `vlib work`. Las señales `w_ptr`, `r_ptr`, `w_data` y `r_data` pueden visualizarse en binario con **Radix → Binary**. Los testbenches incluyen aserciones y mensajes `PASS` cuando terminan sus comprobaciones.

## Implementación en la tarjeta Terasic DE0

**Dispositivo esperado:** Cyclone III **EP3C16F484C6**, tarjeta **DE0 original** (no DE0-CV). Usa `de0_fifo_top` como entidad de nivel superior en Quartus. Para programar la FPGA se necesitan las asignaciones de pines de la DE0 según su manual; las asignaciones de pines se configuran por separado en Quartus.

| Recurso | Función |
|---|---|
| `CLOCK_50` | Reloj físico de 50 MHz |
| `SW9..SW6` | Dato de entrada de 4 bits |
| `SW1` | Reset activo en alto (1 reinicia; 0 funciona) |
| `BUTTON2` | Escribir un dato |
| `BUTTON1` | Retirar el primer dato |
| `HEX3` | Apuntador de escritura |
| `HEX2` | Dato de entrada |
| `HEX1` | Apuntador de lectura |
| `HEX0` | Dato de salida |
| `LEDG8` | `full` (memoria llena) |
| `LEDG7` | `empty` (memoria vacía) |

### Secuencia de verificación experimental

Los cuatro caracteres de la columna «Displays» corresponden a `HEX3`, `HEX2`, `HEX1` y `HEX0`, de izquierda a derecha.

| Prueba | Displays esperados | Observación |
|---|---|---|
| Reset y entrada = 0 | `0000` | `empty = 1` |
| Escribir el 5 (`0101`) | `1505` | Primer dato guardado |
| Cambiar entrada a 9 (`1001`) sin escribir | `1905` | La salida continúa en 5 |
| Escribir 9 | `2905` | Segundo dato guardado |
| Leer una vez | `2919` | Sale primero el 5 y queda el 9 |
| Leer otra vez | `2920` | `empty = 1` |
| Reiniciar y escribir el 5 dieciséis veces | `0505` | `full = 1` |
| Intentar escribir 9 estando llena | `0905` | Escritura bloqueada; `full = 1` |
| Leer los dieciséis datos | `0900` | `empty = 1` |

La secuencia anterior se verificó físicamente durante la práctica. Para reproducirla, reinicia la FIFO al comenzar la prueba de llenado.

## Evidencia audiovisual

Video de demostración física: https://youtu.be/RGIPezCiFKw

## Referencias

- Pontificia Universidad Javeriana, Departamento de Electrónica, *Laboratorio No. 6: FIFO Buffer*, guía de la asignatura Diseño de Sistemas Digitales.
- Terasic, *DE0 User Manual*, versión 1.1: https://www.terasic.com.tw/attachment/archive/371/DE0_User_manual_v1.1.pdf
- IEEE Std 1076-2019, *IEEE Standard for VHDL Language Reference Manual*: https://standards.ieee.org/ieee/1076/5179/
