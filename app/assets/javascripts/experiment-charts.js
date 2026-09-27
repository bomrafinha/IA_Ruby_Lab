(() => {
  const palette = ["#ee684d", "#188e91", "#7fa83e", "#7661a8", "#172522"];

  function numberRange(values) {
    const numbers = values.filter((value) => Number.isFinite(value));
    if (!numbers.length) return { min: 0, max: 1 };

    const min = Math.min(...numbers);
    const max = Math.max(...numbers);
    if (min === max) return { min: min - 1, max: max + 1 };

    const padding = (max - min) * 0.12;
    return { min: min - padding, max: max + padding };
  }

  function drawFrame(context, width, height, plot) {
    context.strokeStyle = "rgba(23, 37, 34, 0.18)";
    context.lineWidth = 1;
    context.beginPath();
    context.moveTo(plot.left, plot.top);
    context.lineTo(plot.left, height - plot.bottom);
    context.lineTo(width - plot.right, height - plot.bottom);
    context.stroke();

    context.strokeStyle = "rgba(23, 37, 34, 0.08)";
    for (let index = 1; index < 4; index += 1) {
      const y = plot.top + ((height - plot.top - plot.bottom) * index) / 4;
      context.beginPath();
      context.moveTo(plot.left, y);
      context.lineTo(width - plot.right, y);
      context.stroke();
    }
  }

  function drawLabels(context, chart, width, height, plot) {
    context.fillStyle = "#54625c";
    context.font = "11px Avenir Next, Trebuchet MS, sans-serif";
    context.textAlign = "center";
    const labels = chart.labels || [];
    const usableWidth = width - plot.left - plot.right;
    const step = labels.length > 1 ? usableWidth / (labels.length - 1) : usableWidth;

    labels.forEach((label, index) => {
      if (labels.length > 12 && index % Math.ceil(labels.length / 8) !== 0) return;
      const x = labels.length > 1 ? plot.left + step * index : plot.left + usableWidth / 2;
      context.fillText(label, x, height - plot.bottom + 22);
    });
  }

  function drawLineChart(context, chart, width, height, plot, progress) {
    const series = chart.series || [];
    const values = series.flatMap((item) => item.data || []);
    const range = numberRange(values);
    const usableWidth = width - plot.left - plot.right;
    const usableHeight = height - plot.top - plot.bottom;
    const labels = chart.labels || [];
    const pointX = (index) => labels.length > 1
      ? plot.left + (usableWidth * index) / (labels.length - 1)
      : plot.left + usableWidth / 2;
    const pointY = (value) => plot.top + usableHeight * (1 - (value - range.min) / (range.max - range.min));

    series.forEach((item, seriesIndex) => {
      const data = item.data || [];
      const visibleCount = Math.max(1, Math.ceil(data.length * progress));
      context.strokeStyle = palette[seriesIndex % palette.length];
      context.fillStyle = palette[seriesIndex % palette.length];
      context.lineWidth = 2.5;
      context.beginPath();

      data.slice(0, visibleCount).forEach((value, index) => {
        const x = pointX(index);
        const y = pointY(value);
        if (index === 0) context.moveTo(x, y);
        else context.lineTo(x, y);
      });
      context.stroke();

      data.slice(0, visibleCount).forEach((value, index) => {
        context.beginPath();
        context.arc(pointX(index), pointY(value), 4, 0, Math.PI * 2);
        context.fill();
      });
    });

    drawLabels(context, chart, width, height, plot);
  }

  function drawBarChart(context, chart, width, height, plot, progress) {
    const data = (chart.series && chart.series[0] && chart.series[0].data) || [];
    const range = numberRange(data);
    const usableWidth = width - plot.left - plot.right;
    const usableHeight = height - plot.top - plot.bottom;
    const baseline = height - plot.bottom;
    const gap = Math.max(5, usableWidth / Math.max(data.length, 1) * 0.14);
    const barWidth = Math.max(4, (usableWidth - gap * Math.max(data.length - 1, 0)) / Math.max(data.length, 1));
    const labels = chart.labels || [];

    data.forEach((value, index) => {
      const reveal = Math.max(0, Math.min(1, progress * data.length - index));
      const x = plot.left + index * (barWidth + gap);
      const y = plot.top + usableHeight * (1 - (value - range.min) / (range.max - range.min));
      const barHeight = Math.max(2, baseline - y) * reveal;
      context.fillStyle = palette[index % palette.length];
      context.fillRect(x, baseline - barHeight, barWidth, barHeight);
      if (labels[index]) {
        context.fillStyle = "#54625c";
        context.font = "11px Avenir Next, Trebuchet MS, sans-serif";
        context.textAlign = "center";
        context.fillText(labels[index], x + barWidth / 2, baseline + 22);
      }
    });
  }

  function drawScatterChart(context, chart, width, height, plot, progress) {
    const points = chart.points || [];
    const xRange = numberRange(points.map((point) => point.x));
    const yRange = numberRange(points.map((point) => point.y));
    const usableWidth = width - plot.left - plot.right;
    const usableHeight = height - plot.top - plot.bottom;
    const visibleCount = Math.max(1, Math.ceil(points.length * progress));

    points.slice(0, visibleCount).forEach((point) => {
      const x = plot.left + usableWidth * ((point.x - xRange.min) / (xRange.max - xRange.min));
      const y = plot.top + usableHeight * (1 - (point.y - yRange.min) / (yRange.max - yRange.min));
      context.fillStyle = palette[point.group % palette.length];
      context.beginPath();
      context.arc(x, y, 7, 0, Math.PI * 2);
      context.fill();
      context.strokeStyle = "#faf9f3";
      context.lineWidth = 2;
      context.stroke();
    });
  }

  function mountChart(element) {
    let chart;
    try {
      chart = JSON.parse(element.dataset.experimentChart);
    } catch (_error) {
      return;
    }

    const canvas = element.querySelector("canvas");
    if (!canvas) return;
    const context = canvas.getContext("2d");
    const render = (progress) => {
      const bounds = canvas.getBoundingClientRect();
      const ratio = window.devicePixelRatio || 1;
      const width = Math.max(320, bounds.width);
      const height = 260;
      canvas.width = width * ratio;
      canvas.height = height * ratio;
      context.setTransform(ratio, 0, 0, ratio, 0, 0);
      context.clearRect(0, 0, width, height);

      const plot = { top: 18, right: 20, bottom: 42, left: 34 };
      drawFrame(context, width, height, plot);
      if (chart.type === "scatter") drawScatterChart(context, chart, width, height, plot, progress);
      else if (chart.type === "bar") drawBarChart(context, chart, width, height, plot, progress);
      else drawLineChart(context, chart, width, height, plot, progress);
    };

    const startedAt = performance.now();
    const animate = (now) => {
      const progress = Math.min(1, (now - startedAt) / 1150);
      render(progress);
      if (progress < 1) requestAnimationFrame(animate);
    };

    requestAnimationFrame(animate);
    window.addEventListener("resize", () => render(1), { passive: true });
  }

  function start() {
    document.querySelectorAll("[data-experiment-chart]").forEach(mountChart);
  }

  if (document.readyState === "loading") document.addEventListener("DOMContentLoaded", start);
  else start();
})();
