import numpy as np
import pandas as pd
import plotly.graph_objects as go
import plotly.express as px
from datetime import datetime, timedelta
from shiny import App, reactive, render, ui
from shiny.types import ImgData

# ---------------------------------------------------------------------------
# Fake data generation
# ---------------------------------------------------------------------------
np.random.seed(42)

TURBINE_IDS = [f"WT-{str(i).zfill(3)}" for i in range(1, 13)]
TURBINE_MODELS = ["Vestas V150", "Siemens SG 5.8", "GE Haliade-X", "Nordex N163"]
LOCATIONS = [
    "Parque Eólico Norte", "Parque Eólico Sul",
    "Parque Eólico Leste", "Parque Eólico Oeste",
]
STATUSES = ["Operando", "Manutenção", "Parada", "Alerta"]
STATUS_COLORS = {
    "Operando": "#2ecc71",
    "Manutenção": "#f39c12",
    "Parada": "#e74c3c",
    "Alerta": "#e67e22",
}


def generate_turbine_metadata():
    rows = []
    for tid in TURBINE_IDS:
        rows.append({
            "turbine_id": tid,
            "modelo": np.random.choice(TURBINE_MODELS),
            "localizacao": np.random.choice(LOCATIONS),
            "capacidade_mw": round(np.random.uniform(3.0, 6.0), 1),
            "status": np.random.choice(STATUSES, p=[0.65, 0.15, 0.10, 0.10]),
            "lat": round(np.random.uniform(-8.0, -3.0), 4),
            "lon": round(np.random.uniform(-37.0, -35.0), 4),
        })
    return pd.DataFrame(rows)


def generate_timeseries(hours=168):
    """Generate 7 days of hourly data for all turbines."""
    now = datetime.now()
    timestamps = [now - timedelta(hours=h) for h in range(hours, 0, -1)]
    rows = []
    for tid in TURBINE_IDS:
        base_wind = np.random.uniform(6, 14)
        for ts in timestamps:
            hour_of_day = ts.hour
            # Wind pattern: stronger at night
            wind_mod = 1.2 if hour_of_day < 6 or hour_of_day > 20 else 0.85
            wind_speed = max(0, np.random.normal(base_wind * wind_mod, 2.5))
            # Power ~ cubic relation with wind, capped at rated capacity
            rated = np.random.uniform(3.0, 6.0)
            power = min(rated, (wind_speed / 12) ** 3 * rated) if wind_speed > 3.5 else 0
            power = max(0, power + np.random.normal(0, 0.1))
            rows.append({
                "timestamp": ts,
                "turbine_id": tid,
                "wind_speed_ms": round(wind_speed, 2),
                "power_mw": round(power, 3),
                "rpm": round(max(0, wind_speed * 1.1 + np.random.normal(0, 0.5)), 1),
                "temp_nacelle_c": round(np.random.normal(42, 5), 1),
                "vibration_mm_s": round(abs(np.random.normal(2.5, 1.2)), 2),
            })
    return pd.DataFrame(rows)


def generate_alerts(n=25):
    now = datetime.now()
    severities = ["Crítico", "Alto", "Médio", "Baixo"]
    alert_types = [
        "Vibração excessiva", "Temperatura alta na nacele",
        "Queda de produção", "Falha no conversor",
        "Desalinhamento do rotor", "Sensor offline",
        "Velocidade do vento acima do limite", "Erro de comunicação",
    ]
    rows = []
    for _ in range(n):
        rows.append({
            "timestamp": now - timedelta(hours=np.random.randint(0, 168)),
            "turbine_id": np.random.choice(TURBINE_IDS),
            "tipo_alerta": np.random.choice(alert_types),
            "severidade": np.random.choice(severities, p=[0.1, 0.25, 0.4, 0.25]),
            "resolvido": np.random.choice([True, False], p=[0.6, 0.4]),
        })
    df = pd.DataFrame(rows).sort_values("timestamp", ascending=False).reset_index(drop=True)
    return df


# Pre-generate data
metadata_df = generate_turbine_metadata()
ts_df = generate_timeseries()
alerts_df = generate_alerts()

# ---------------------------------------------------------------------------
# UI
# ---------------------------------------------------------------------------

BRAND_COLOR = "#1a1a2e"
ACCENT = "#0f3460"
HIGHLIGHT = "#16c79a"

css = """
body { background-color: #0d1117; color: #c9d1d9; font-family: 'Segoe UI', sans-serif; }
.card { background: #161b22; border: 1px solid #30363d; border-radius: 12px; padding: 20px; margin-bottom: 16px; }
.kpi-card { text-align: center; padding: 24px 16px; }
.kpi-value { font-size: 2.2rem; font-weight: 700; color: #58a6ff; }
.kpi-label { font-size: 0.85rem; color: #8b949e; text-transform: uppercase; letter-spacing: 1px; margin-top: 4px; }
.kpi-delta { font-size: 0.8rem; margin-top: 4px; }
.delta-up { color: #2ecc71; }
.delta-down { color: #e74c3c; }
h2 { color: #58a6ff; border-bottom: 2px solid #21262d; padding-bottom: 8px; }
.status-badge { padding: 3px 10px; border-radius: 12px; font-size: 0.75rem; font-weight: 600; color: #fff; display: inline-block; }
.header-bar { background: linear-gradient(135deg, #0d1117, #161b22); padding: 20px 30px; border-bottom: 2px solid #58a6ff; margin-bottom: 20px; }
.header-title { font-size: 1.6rem; font-weight: 700; color: #58a6ff; }
.header-subtitle { font-size: 0.85rem; color: #8b949e; }
.shiny-input-container { color: #c9d1d9; }
select, input { background: #0d1117 !important; color: #c9d1d9 !important; border: 1px solid #30363d !important; }
tbody{color: white}
"""

app_ui = ui.page_fluid(
    ui.tags.style(css),
    # Header
    ui.div(
        ui.div("⚡ Wind Turbine Monitor", class_="header-title"),
        ui.div("Painel de monitoramento em tempo real — Dados simulados (fake)", class_="header-subtitle"),
        class_="header-bar",
    ),
    # Filters
    ui.layout_columns(
        ui.input_select(
            "park_filter", "Parque Eólico",
            choices=["Todos"] + sorted(metadata_df["localizacao"].unique().tolist()),
            selected="Todos",
        ),
        ui.input_select(
            "period_filter", "Período",
            choices={"24": "Últimas 24h", "48": "Últimas 48h", "72": "Últimas 72h", "168": "Últimos 7 dias"},
            selected="168",
        ),
        col_widths=[3, 3],
    ),
    # KPI row
    ui.layout_columns(
        ui.div(ui.output_ui("kpi_power"), class_="card kpi-card"),
        ui.div(ui.output_ui("kpi_wind"), class_="card kpi-card"),
        ui.div(ui.output_ui("kpi_availability"), class_="card kpi-card"),
        ui.div(ui.output_ui("kpi_alerts"), class_="card kpi-card"),
        col_widths=[3, 3, 3, 3],
    ),
    # Charts row 1
    ui.layout_columns(
        ui.div(
            ui.h2("Geração de Energia (MW)"),
            ui.output_ui("chart_power_ts"),
            class_="card",
        ),
        ui.div(
            ui.h2("Distribuição — Velocidade do Vento"),
            ui.output_ui("chart_wind_dist"),
            class_="card",
        ),
        col_widths=[8, 4],
    ),
    # Charts row 2
    ui.layout_columns(
        ui.div(
            ui.h2("Eficiência por Turbina (%)"),
            ui.output_ui("chart_efficiency"),
            class_="card",
        ),
        ui.div(
            ui.h2("Temperatura Nacele vs Vibração"),
            ui.output_ui("chart_scatter"),
            class_="card",
        ),
        col_widths=[6, 6],
    ),
    # Status table & Alerts
    ui.layout_columns(
        ui.div(
            ui.h2("Status das Turbinas"),
            ui.output_ui("table_status"),
            class_="card",
        ),
        ui.div(
            ui.h2("Alertas Recentes"),
            ui.output_ui("table_alerts"),
            class_="card",
        ),
        col_widths=[6, 6],
    ),
)


# ---------------------------------------------------------------------------
# Server
# ---------------------------------------------------------------------------

PLOT_LAYOUT = dict(
    paper_bgcolor="rgba(0,0,0,0)",
    plot_bgcolor="rgba(0,0,0,0)",
    font=dict(color="#c9d1d9", size=11),
    margin=dict(l=40, r=20, t=30, b=40),
    xaxis=dict(gridcolor="#21262d"),
    yaxis=dict(gridcolor="#21262d"),
    legend=dict(bgcolor="rgba(0,0,0,0)"),
)


def server(input, output, session):

    @reactive.calc
    def filtered_ts():
        hours = int(input.period_filter())
        cutoff = datetime.now() - timedelta(hours=hours)
        df = ts_df[ts_df["timestamp"] >= cutoff].copy()
        if input.park_filter() != "Todos":
            turb_ids = metadata_df[metadata_df["localizacao"] == input.park_filter()]["turbine_id"].tolist()
            df = df[df["turbine_id"].isin(turb_ids)]
        return df

    @reactive.calc
    def filtered_meta():
        if input.park_filter() != "Todos":
            return metadata_df[metadata_df["localizacao"] == input.park_filter()].copy()
        return metadata_df.copy()

    # ---- KPIs ----
    @output
    @render.ui
    def kpi_power():
        df = filtered_ts()
        total = df["power_mw"].sum()
        return ui.HTML(
            f'''<div class="kpi-value">{total:,.0f} MWh</div>
            <div class="kpi-label">Energia Gerada</div>
            <div class="kpi-delta delta-up">▲ período selecionado</div>'''
        )

    @output
    @render.ui
    def kpi_wind():
        df = filtered_ts()
        avg = df["wind_speed_ms"].mean()
        return ui.HTML(
            f'''<div class="kpi-value">{avg:.1f} m/s</div>
            <div class="kpi-label">Vel. Média do Vento</div>
            <div class="kpi-delta">Média do período</div>'''
        )

    @output
    @render.ui
    def kpi_availability():
        meta = filtered_meta()
        operating = (meta["status"] == "Operando").sum()
        total = len(meta)
        pct = operating / total * 100 if total > 0 else 0
        color_cls = "delta-up" if pct >= 80 else "delta-down"
        return ui.HTML(
            f'''<div class="kpi-value">{pct:.0f}%</div>
            <div class="kpi-label">Disponibilidade</div>
            <div class="kpi-delta {color_cls}">{operating}/{total} turbinas operando</div>'''
        )

    @output
    @render.ui
    def kpi_alerts():
        open_alerts = (~alerts_df["resolvido"]).sum()
        color = "color: #e74c3c;" if open_alerts > 5 else "color: #f39c12;"
        return ui.HTML(
            f'''<div class="kpi-value" style="{color}">{open_alerts}</div>
            <div class="kpi-label">Alertas Abertos</div>
            <div class="kpi-delta delta-down">Requerem atenção</div>'''
        )

    # ---- Charts ----
    @output
    @render.ui
    def chart_power_ts():
        df = filtered_ts()
        agg = df.groupby("timestamp")["power_mw"].sum().reset_index()
        fig = go.Figure()
        fig.add_trace(go.Scatter(
            x=agg["timestamp"], y=agg["power_mw"],
            mode="lines", fill="tozeroy",
            line=dict(color="#58a6ff", width=1.5),
            fillcolor="rgba(88,166,255,0.15)",
            name="Potência Total",
        ))
        fig.update_layout(**PLOT_LAYOUT, height=320)
        fig.update_xaxes(title_text="")
        fig.update_yaxes(title_text="MW")
        return ui.HTML(fig.to_html(full_html=False, include_plotlyjs="cdn"))

    @output
    @render.ui
    def chart_wind_dist():
        df = filtered_ts()
        fig = go.Figure()
        fig.add_trace(go.Histogram(
            x=df["wind_speed_ms"], nbinsx=30,
            marker_color="#16c79a", opacity=0.85,
            name="Velocidade",
        ))
        fig.update_layout(**PLOT_LAYOUT, height=320, bargap=0.05)
        fig.update_xaxes(title_text="Velocidade (m/s)")
        fig.update_yaxes(title_text="Frequência")
        return ui.HTML(fig.to_html(full_html=False, include_plotlyjs="cdn"))

    @output
    @render.ui
    def chart_efficiency():
        df = filtered_ts()
        meta = filtered_meta()
        eff_rows = []
        for _, row in meta.iterrows():
            tid = row["turbine_id"]
            cap = row["capacidade_mw"]
            t_df = df[df["turbine_id"] == tid]
            if len(t_df) > 0:
                avg_power = t_df["power_mw"].mean()
                eff = min(100, avg_power / cap * 100)
            else:
                eff = 0
            eff_rows.append({"turbine_id": tid, "eficiencia": round(eff, 1)})
        eff_df = pd.DataFrame(eff_rows).sort_values("eficiencia", ascending=True)
        colors = ["#2ecc71" if e >= 50 else "#f39c12" if e >= 30 else "#e74c3c" for e in eff_df["eficiencia"]]
        fig = go.Figure(go.Bar(
            x=eff_df["eficiencia"], y=eff_df["turbine_id"],
            orientation="h", marker_color=colors,
            text=[f"{v}%" for v in eff_df["eficiencia"]],
            textposition="outside",
        ))
        fig.update_layout(**PLOT_LAYOUT, height=380)
        fig.update_xaxes(title_text="Eficiência (%)", range=[0, 110])
        fig.update_yaxes(title_text="")
        return ui.HTML(fig.to_html(full_html=False, include_plotlyjs="cdn"))

    @output
    @render.ui
    def chart_scatter():
        df = filtered_ts().sample(min(500, len(filtered_ts())), random_state=1)
        fig = px.scatter(
            df, x="temp_nacelle_c", y="vibration_mm_s",
            color="turbine_id", opacity=0.6,
            labels={"temp_nacelle_c": "Temperatura (°C)", "vibration_mm_s": "Vibração (mm/s)"},
        )
        fig.update_layout(**PLOT_LAYOUT, height=380, showlegend=False)
        return ui.HTML(fig.to_html(full_html=False, include_plotlyjs="cdn"))

    # ---- Tables ----
    @output
    @render.ui
    def table_status():
        meta = filtered_meta()
        rows_html = ""
        for _, row in meta.iterrows():
            sc = STATUS_COLORS.get(row["status"], "#8b949e")
            badge = f'<span class="status-badge" style="background:{sc}">{row["status"]}</span>'
            rows_html += f"""<tr>
                <td style="padding:8px">{row["turbine_id"]}</td>
                <td style="padding:8px">{row["modelo"]}</td>
                <td style="padding:8px">{row["localizacao"]}</td>
                <td style="padding:8px">{row["capacidade_mw"]} MW</td>
                <td style="padding:8px">{badge}</td>
            </tr>"""
        return ui.HTML(f"""
        <div style="overflow-x:auto">
        <table style="width:100%; border-collapse:collapse;">
            <thead><tr style="border-bottom:2px solid #30363d;">
                <th style="padding:8px;text-align:left">Turbina</th>
                <th style="padding:8px;text-align:left">Modelo</th>
                <th style="padding:8px;text-align:left">Localização</th>
                <th style="padding:8px;text-align:left">Capacidade</th>
                <th style="padding:8px;text-align:left">Status</th>
            </tr></thead>
            <tbody>{rows_html}</tbody>
        </table>
        </div>""")

    @output
    @render.ui
    def table_alerts():
        sev_colors = {"Crítico": "#e74c3c", "Alto": "#e67e22", "Médio": "#f39c12", "Baixo": "#8b949e"}
        rows_html = ""
        for _, row in alerts_df.head(15).iterrows():
            sc = sev_colors.get(row["severidade"], "#8b949e")
            badge = f'<span class="status-badge" style="background:{sc}">{row["severidade"]}</span>'
            resolved = "✅" if row["resolvido"] else "⏳"
            ts_str = row["timestamp"].strftime("%d/%m %H:%M")
            rows_html += f"""<tr>
                <td style="padding:6px">{ts_str}</td>
                <td style="padding:6px">{row["turbine_id"]}</td>
                <td style="padding:6px">{row["tipo_alerta"]}</td>
                <td style="padding:6px">{badge}</td>
                <td style="padding:6px;text-align:center">{resolved}</td>
            </tr>"""
        return ui.HTML(f"""
        <div style="overflow-x:auto; max-height:400px; overflow-y:auto;">
        <table style="width:100%; border-collapse:collapse;">
            <thead><tr style="border-bottom:2px solid #30363d;">
                <th style="padding:6px;text-align:left">Data</th>
                <th style="padding:6px;text-align:left">Turbina</th>
                <th style="padding:6px;text-align:left">Tipo</th>
                <th style="padding:6px;text-align:left">Severidade</th>
                <th style="padding:6px;text-align:center">Resolvido</th>
            </tr></thead>
            <tbody>{rows_html}</tbody>
        </table>
        </div>""")


app = App(app_ui, server)
