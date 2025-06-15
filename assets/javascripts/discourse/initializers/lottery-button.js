import Component from "@ember/component";
import { inject as service } from "@ember/service";
import { action } from "@ember/object";

export default class LotteryButtonComponent extends Component {
  @service ajax;
  @service currentUser;
  @service notifications;

  isLoading = false;
  winners = [];
  drawnAt = null;

  get canDraw() {
    if (!this.currentUser) return false;
    const { topic } = this;
    if (!topic) return false;

    // 只有楼主、管理员、版主可以点击抽奖
    const isAuthor = this.currentUser.id === topic.details.created_by.id;
    const isAdmin = this.currentUser.admin;
    const isMod = this.currentUser.moderator;
    return isAuthor || isAdmin || isMod;
  }

  @action
  async drawLottery() {
    if (!this.canDraw) {
      this.notifications.alert("你没有权限抽奖");
      return;
    }
    this.set('isLoading', true);
    try {
      const response = await this.ajax.post("/lottery/draw", {
        data: {
          topic_id: this.topic.id,
          count: this.drawCount || 1
        }
      });
      this.set('winners', response.winners);
      this.set('drawnAt', new Date().toISOString());
      this.notifications.success("抽奖成功！");
    } catch (e) {
      this.notifications.alert("抽奖失败：" + (e.jqXHR?.responseJSON?.errors || e.message));
    } finally {
      this.set('isLoading', false);
    }
  }
}
