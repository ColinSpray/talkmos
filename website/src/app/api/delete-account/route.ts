import { NextRequest, NextResponse } from "next/server";

export async function POST(request: NextRequest) {
  try {
    const body = await request.json();
    const { email, username, reason, confirmCheck } = body;

    // Validation
    if (!email || typeof email !== "string" || !email.includes("@")) {
      return NextResponse.json(
        { error: "A valid email address is required." },
        { status: 400 }
      );
    }

    if (!confirmCheck) {
      return NextResponse.json(
        { error: "You must confirm that you understand account deletion rules." },
        { status: 400 }
      );
    }

    const timestamp = new Date();
    // Calculate 30-day soft delete grace period expiration date
    const gracePeriodDays = 30;
    const scheduledHardDeleteAt = new Date(timestamp.getTime() + gracePeriodDays * 24 * 60 * 60 * 1000);

    // Generate a unique soft delete reference ticket ID
    const ticketId = `SOFT-DEL-${Date.now().toString(36).toUpperCase()}-${Math.random().toString(36).substring(2, 6).toUpperCase()}`;

    // Soft delete payload state record
    const softDeletedAccountRecord = {
      ticketId,
      email,
      username: username || null,
      status: "SOFT_DELETED",
      isSoftDeleted: true,
      softDeletedAt: timestamp.toISOString(),
      scheduledHardDeleteAt: scheduledHardDeleteAt.toISOString(),
      gracePeriodDays,
      reason: reason || "User requested deletion",
    };

    // In a live production database (e.g. PostgreSQL / MongoDB / Firebase), this would execute:
    // await db.users.update({ where: { email }, data: { isSoftDeleted: true, deletedAt: timestamp, status: 'SOFT_DELETED' } });
    console.log("[BACKEND SOFT DELETE EXECUTED]:", JSON.stringify(softDeletedAccountRecord, null, 2));

    return NextResponse.json({
      success: true,
      mode: "SOFT_DELETE",
      ticketId: softDeletedAccountRecord.ticketId,
      email: softDeletedAccountRecord.email,
      status: softDeletedAccountRecord.status,
      softDeletedAt: softDeletedAccountRecord.softDeletedAt,
      scheduledHardDeleteAt: softDeletedAccountRecord.scheduledHardDeleteAt,
      gracePeriodDays: softDeletedAccountRecord.gracePeriodDays,
      message: `Account state updated to SOFT DELETED. Deactivated immediately and scheduled for permanent hard purge on ${scheduledHardDeleteAt.toLocaleDateString()}.`,
    });
  } catch (error) {
    console.error("[SOFT DELETE API ERROR]:", error);
    return NextResponse.json(
      { error: "An unexpected server error occurred while processing soft deletion." },
      { status: 500 }
    );
  }
}
