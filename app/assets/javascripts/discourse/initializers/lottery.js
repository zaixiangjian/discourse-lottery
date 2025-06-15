import { withPluginApi } from "discourse/lib/plugin-api";

export default {
  name: "lottery",

  initialize() {
    withPluginApi("0.8", (api) => {
      api.registerComposerComponent("lottery-button", {
        templateName: "components/lottery-button",
        isSidecar: true,
      });

      api.decorateWidget("post-stream:post-controls", (helper) => {
        const currentUser = helper.currentUser;
        const post = helper.getModel();

        // 只在楼主帖子下显示按钮
        if (!post || !post.topic || post.post_number !== 1) {
          return;
        }

        // 判断权限
        const isAuthor = currentUser && currentUser.id === post.topic.posters[0].user_id;
        const isAdmin = currentUser && currentUser.admin;
        const isMod = currentUser && currentUser.moderator;
        if (!(isAuthor || isAdmin || isMod)) {
          return;
        }

        return helper.h("lottery-button", {
          topic: post.topic,
        });
      });
    });
  },
};
