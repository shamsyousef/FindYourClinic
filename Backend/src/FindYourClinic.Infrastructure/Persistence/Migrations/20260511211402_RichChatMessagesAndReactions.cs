using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace FindYourClinic.Infrastructure.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class RichChatMessagesAndReactions : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<int>(
                name: "MediaDurationSeconds",
                table: "ChatMessages",
                type: "int",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "MediaThumbnailUrl",
                table: "ChatMessages",
                type: "nvarchar(1000)",
                maxLength: 1000,
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "MediaUrl",
                table: "ChatMessages",
                type: "nvarchar(1000)",
                maxLength: 1000,
                nullable: true);

            migrationBuilder.AddColumn<Guid>(
                name: "ReplyToMessageId",
                table: "ChatMessages",
                type: "uniqueidentifier",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "Type",
                table: "ChatMessages",
                type: "int",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.CreateTable(
                name: "MessageReactions",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    MessageId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    UserId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    Emoji = table.Column<string>(type: "nvarchar(16)", maxLength: 16, nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "datetime2", nullable: false),
                    CreatedBy = table.Column<Guid>(type: "uniqueidentifier", nullable: true),
                    UpdatedAt = table.Column<DateTime>(type: "datetime2", nullable: true),
                    UpdatedBy = table.Column<Guid>(type: "uniqueidentifier", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_MessageReactions", x => x.Id);
                    table.ForeignKey(
                        name: "FK_MessageReactions_AspNetUsers_UserId",
                        column: x => x.UserId,
                        principalTable: "AspNetUsers",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_MessageReactions_ChatMessages_MessageId",
                        column: x => x.MessageId,
                        principalTable: "ChatMessages",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_ChatMessages_ReplyToMessageId",
                table: "ChatMessages",
                column: "ReplyToMessageId");

            migrationBuilder.CreateIndex(
                name: "IX_MessageReactions_MessageId_UserId_Emoji",
                table: "MessageReactions",
                columns: new[] { "MessageId", "UserId", "Emoji" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_MessageReactions_UserId",
                table: "MessageReactions",
                column: "UserId");

            migrationBuilder.AddForeignKey(
                name: "FK_ChatMessages_ChatMessages_ReplyToMessageId",
                table: "ChatMessages",
                column: "ReplyToMessageId",
                principalTable: "ChatMessages",
                principalColumn: "Id",
                onDelete: ReferentialAction.Restrict);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_ChatMessages_ChatMessages_ReplyToMessageId",
                table: "ChatMessages");

            migrationBuilder.DropTable(
                name: "MessageReactions");

            migrationBuilder.DropIndex(
                name: "IX_ChatMessages_ReplyToMessageId",
                table: "ChatMessages");

            migrationBuilder.DropColumn(
                name: "MediaDurationSeconds",
                table: "ChatMessages");

            migrationBuilder.DropColumn(
                name: "MediaThumbnailUrl",
                table: "ChatMessages");

            migrationBuilder.DropColumn(
                name: "MediaUrl",
                table: "ChatMessages");

            migrationBuilder.DropColumn(
                name: "ReplyToMessageId",
                table: "ChatMessages");

            migrationBuilder.DropColumn(
                name: "Type",
                table: "ChatMessages");
        }
    }
}
