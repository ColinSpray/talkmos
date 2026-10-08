package com.talkmos.app

import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.Path
import android.graphics.RectF
import android.graphics.drawable.Icon

/// Icons for the real system PiP window's action buttons (see
/// MainActivity.kt's buildPipActions()) — Android's own PiP chrome, not
/// anything Flutter draws, since a real PiP window doesn't let touches
/// through to the underlying app content beyond tap-to-expand.
///
/// Drawn with Canvas primitives rather than as vector-drawable XML
/// resources: a couple of drawCircle/drawArc/drawRoundRect calls are easy to
/// get right from first principles, where hand-typed SVG path data would
/// have been an unverifiable guess.
object PipActionIcons {
    private const val SIZE = 72

    private fun newCanvas(): Pair<Bitmap, Canvas> {
        val bitmap = Bitmap.createBitmap(SIZE, SIZE, Bitmap.Config.ARGB_8888)
        return bitmap to Canvas(bitmap)
    }

    private fun whiteFill() = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        color = Color.WHITE
        style = Paint.Style.FILL
    }

    fun mic(muted: Boolean): Icon {
        val (bitmap, canvas) = newCanvas()
        val paint = whiteFill()

        // Capsule body.
        canvas.drawRoundRect(
            RectF(SIZE * 0.38f, SIZE * 0.10f, SIZE * 0.62f, SIZE * 0.54f),
            SIZE * 0.12f, SIZE * 0.12f, paint
        )

        // Stand (open arc under the capsule) + stem + base.
        paint.style = Paint.Style.STROKE
        paint.strokeWidth = SIZE * 0.055f
        paint.strokeCap = Paint.Cap.ROUND
        canvas.drawArc(
            RectF(SIZE * 0.24f, SIZE * 0.32f, SIZE * 0.76f, SIZE * 0.76f),
            20f, 140f, false, paint
        )
        canvas.drawLine(SIZE * 0.5f, SIZE * 0.70f, SIZE * 0.5f, SIZE * 0.86f, paint)
        canvas.drawLine(SIZE * 0.35f, SIZE * 0.86f, SIZE * 0.65f, SIZE * 0.86f, paint)

        if (muted) {
            paint.color = Color.parseColor("#EF4444")
            paint.strokeWidth = SIZE * 0.08f
            canvas.drawLine(SIZE * 0.14f, SIZE * 0.14f, SIZE * 0.86f, SIZE * 0.86f, paint)
        }
        return Icon.createWithBitmap(bitmap)
    }

    fun speaker(on: Boolean): Icon {
        val (bitmap, canvas) = newCanvas()
        val paint = whiteFill()

        // Speaker cone: a small box plus a wedge pointing right.
        val cone = Path().apply {
            moveTo(SIZE * 0.14f, SIZE * 0.38f)
            lineTo(SIZE * 0.36f, SIZE * 0.38f)
            lineTo(SIZE * 0.56f, SIZE * 0.18f)
            lineTo(SIZE * 0.56f, SIZE * 0.82f)
            lineTo(SIZE * 0.36f, SIZE * 0.62f)
            lineTo(SIZE * 0.14f, SIZE * 0.62f)
            close()
        }
        canvas.drawPath(cone, paint)

        paint.style = Paint.Style.STROKE
        paint.strokeCap = Paint.Cap.ROUND
        if (on) {
            paint.strokeWidth = SIZE * 0.05f
            canvas.drawArc(RectF(SIZE * 0.58f, SIZE * 0.30f, SIZE * 0.78f, SIZE * 0.70f), -50f, 100f, false, paint)
            canvas.drawArc(RectF(SIZE * 0.64f, SIZE * 0.16f, SIZE * 0.90f, SIZE * 0.84f), -50f, 100f, false, paint)
        } else {
            paint.color = Color.parseColor("#EF4444")
            paint.strokeWidth = SIZE * 0.07f
            canvas.drawLine(SIZE * 0.60f, SIZE * 0.22f, SIZE * 0.88f, SIZE * 0.78f, paint)
            canvas.drawLine(SIZE * 0.88f, SIZE * 0.22f, SIZE * 0.60f, SIZE * 0.78f, paint)
        }
        return Icon.createWithBitmap(bitmap)
    }

    fun hangUp(): Icon {
        val (bitmap, canvas) = newCanvas()
        val bg = Paint(Paint.ANTI_ALIAS_FLAG).apply { color = Color.parseColor("#EF4444") }
        canvas.drawCircle(SIZE / 2f, SIZE / 2f, SIZE / 2f, bg)

        val handset = whiteFill()
        canvas.save()
        canvas.rotate(135f, SIZE / 2f, SIZE / 2f)
        canvas.drawRoundRect(
            RectF(SIZE * 0.26f, SIZE * 0.43f, SIZE * 0.74f, SIZE * 0.57f),
            SIZE * 0.07f, SIZE * 0.07f, handset
        )
        canvas.restore()
        return Icon.createWithBitmap(bitmap)
    }
}
